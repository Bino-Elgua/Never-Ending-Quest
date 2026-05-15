import json
import os
from typing import List, Dict, Any, Optional
from openai import OpenAI
import config
from core.managers.session_manager import SessionManager
from core.managers.campaign_manager import CampaignManager
from core.managers.pacing_conductor import PacingConductor
from core.ai.harden_service import harden_dm_output
from utils.file_operations import safe_read_json, safe_write_json
from utils.enhanced_logger import debug, info, error
from utils.openrouter_client import OpenRouterClient

from core.generators.map_generator import MapGenerator
from core.ai.music_orchestrator import MusicOrchestrator

class GameManager:
    """
    Central orchestrator for a single game session. 
    Scopes all managers and state to a specific session_id.
    """

    def __init__(self, session_id: str):
        self.session_id = session_id
        self.session = SessionManager(session_id)
        self.campaign_manager = CampaignManager(self.session)
        self.pacing_conductor = PacingConductor(session_id)
        self.map_generator = MapGenerator()
        self.music_orchestrator = MusicOrchestrator()
        
        # Initialize clients
        base_url = getattr(config, 'OPENAI_BASE_URL', None)
        self.client = OpenAI(api_key=config.OPENAI_API_KEY, base_url=base_url)
        self.openrouter = OpenRouterClient() if getattr(config, 'USE_OPENROUTER', False) else None
        
        # Session-specific state flags
        self.held_response = None
        self.awaiting_combat_resolution = False

    def get_conversation_history(self) -> List[Dict[str, Any]]:
        history_file = self.session.get_path("modules/conversation_history/conversation_history.json")
        return safe_read_json(history_file) or []

    def save_conversation_history(self, history: List[Dict[str, Any]]):
        history_file = self.session.get_path("modules/conversation_history/conversation_history.json")
        safe_write_json(history_file, history)

    async def process_user_input(self, user_input: str, username: str = "Player") -> Dict[str, Any]:
        """Process player input and return hardened AI response"""
        history = self.get_conversation_history()
        
        # Add user message
        history.append({
            "role": "user", 
            "content": user_input,
            "username": username
        })
        
        try:
            raw_content = None
            
            # Try OpenRouter first if enabled
            if self.openrouter and getattr(config, 'USE_OPENROUTER', False):
                try:
                    # Filter history to only include role and content for OpenRouter
                    or_history = [{"role": m["role"], "content": m["content"]} for m in history]
                    raw_content = self.openrouter.chat(or_history)
                    if raw_content:
                        info(f"GAME_MANAGER: Received response from OpenRouter")
                except Exception as e:
                    error(f"GAME_MANAGER: OpenRouter failed: {e}")
            
            # Fallback to direct OpenAI client
            if not raw_content:
                response = self.client.chat.completions.create(
                    model=config.DM_MAIN_MODEL,
                    messages=history,
                    temperature=0.8
                )
                raw_content = response.choices[0].message.content
                info(f"GAME_MANAGER: Received response from OpenAI")
            
            # Harden the output
            hardened_data, success = harden_dm_output(raw_content)
            
            final_content = hardened_data['narration'] if success else raw_content
            actions = hardened_data.get('actions', []) if success else []
            
            # Check for map generation triggers in actions
            for action in actions:
                if action['action'] in ['createEncounter', 'transitionLocation']:
                    desc = action['parameters'].get('description', final_content)
                    env = action['parameters'].get('environment', 'unknown')
                    
                    # Generate map in background thread to not block DM response
                    import threading
                    def bg_generate_map(campaign_id, map_desc, map_env):
                        try:
                            info(f"GAME_MANAGER: Starting background map generation for {campaign_id}")
                            map_url = self.map_generator.generate_battle_map(map_desc, map_env)
                            if map_url:
                                local_path = self.map_generator.save_map(campaign_id, map_url)
                                # We can't easily update the 'action' already sent to client, 
                                # but we can emit a separate update or just save it for next request.
                                # For now, we just ensure it's saved locally.
                                info(f"GAME_MANAGER: Background map generation complete for {campaign_id}")
                        except Exception as e:
                            error(f"GAME_MANAGER: Background map generation failed: {e}")
                    
                    threading.Thread(target=bg_generate_map, args=(self.session_id, desc, env), daemon=True).start()
                    
                    # Add a placeholder/flag that map is being generated
                    action['parameters']['map_generating'] = True
            
            # Update history with assistant response
            history.append({
                "role": "assistant",
                "content": final_content,
                "actions": actions
            })
            self.save_conversation_history(history)
            
            return {
                "type": "narration",
                "content": final_content,
                "actions": actions,
                "username": "Dungeon Master"
            }
            
        except Exception as e:
            error(f"GAME_MANAGER: Error processing input for {self.session_id}: {e}")
            return {
                "type": "error",
                "content": f"The weave of magic was interrupted: {str(e)}"
            }
