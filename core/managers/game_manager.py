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
        self.client = OpenAI(api_key=config.OPENAI_API_KEY)
        
        # Session-specific state flags
        self.held_response = None
        self.awaiting_combat_resolution = False

    async def process_user_input(self, user_input: str, username: str = "Player") -> Dict[str, Any]:
        """Process player input and return hardened AI response"""
        # ... history and response logic ...
        # (Assuming response and actions are already retrieved and hardened)
        
        # Check for map generation triggers
        for action in actions:
            if action['action'] in ['createEncounter', 'transitionLocation']:
                desc = action['parameters'].get('description', final_content)
                env = action['parameters'].get('environment', 'unknown')
                
                # Generate map in background
                map_url = self.map_generator.generate_battle_map(desc, env)
                if map_url:
                    local_path = self.map_generator.save_map(self.session_id, map_url)
                    action['parameters']['map_url'] = map_url
                    action['parameters']['local_map_path'] = local_path

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
        
        # Get AI Response (simplified for evolution phase)
        # In production, this calls get_ai_response with full context
        try:
            response = self.client.chat.completions.create(
                model=config.DM_MAIN_MODEL,
                messages=history,
                temperature=0.8
            )
            raw_content = response.choices[0].message.content
            
            # Harden the output
            hardened_data, success = harden_dm_output(raw_content)
            
            final_content = hardened_data['narration'] if success else raw_content
            actions = hardened_data.get('actions', []) if success else []
            
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
                "content": "The weave of magic was interrupted. Please try again."
            }
