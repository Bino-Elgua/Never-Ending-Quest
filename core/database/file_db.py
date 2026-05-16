import os
import json
from typing import Dict, Any, List, Optional
from core.database.base import DatabaseService
from utils.encoding_utils import safe_json_load, safe_json_dump
from core.managers.session_manager import SessionManager

class FileDatabaseService(DatabaseService):
    """File-based implementation of DatabaseService, maintaining backward compatibility."""
    
    def _get_session_manager(self, session_id: str) -> SessionManager:
        return SessionManager(session_id)

    def get_party_tracker(self, session_id: str) -> Optional[Dict[str, Any]]:
        manager = self._get_session_manager(session_id)
        path = manager.get_path("party_tracker.json")
        return safe_json_load(path)

    def save_party_tracker(self, session_id: str, data: Dict[str, Any]) -> bool:
        manager = self._get_session_manager(session_id)
        path = manager.get_path("party_tracker.json")
        return safe_json_dump(data, path)

    def get_character(self, session_id: str, character_name: str) -> Optional[Dict[str, Any]]:
        manager = self._get_session_manager(session_id)
        # Assuming character files are in characters/ folder within session
        path = manager.get_path(f"characters/{character_name}.json")
        return safe_json_load(path)

    def save_character(self, session_id: str, character_name: str, data: Dict[str, Any]) -> bool:
        manager = self._get_session_manager(session_id)
        path = manager.get_path(f"characters/{character_name}.json")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        return safe_json_dump(data, path)

    def get_current_location(self, session_id: str) -> Optional[Dict[str, Any]]:
        manager = self._get_session_manager(session_id)
        path = manager.get_path("current_location.json")
        return safe_json_load(path)

    def save_current_location(self, session_id: str, data: Dict[str, Any]) -> bool:
        manager = self._get_session_manager(session_id)
        path = manager.get_path("current_location.json")
        return safe_json_dump(data, path)

    def get_conversation_history(self, session_id: str) -> List[Dict[str, Any]]:
        manager = self._get_session_manager(session_id)
        path = manager.get_path("modules/conversation_history/conversation_history.json")
        return safe_json_load(path) or []

    def save_conversation_history(self, session_id: str, history: List[Dict[str, Any]]) -> bool:
        manager = self._get_session_manager(session_id)
        path = manager.get_path("modules/conversation_history/conversation_history.json")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        return safe_json_dump(history, path)

    def archive_conversation_history(self, session_id: str, module_name: str, sequence: int, history: List[Dict[str, Any]]) -> bool:
        manager = self._get_session_manager(session_id)
        path = manager.get_path(f"modules/campaign_archives/{module_name}_conversation_{sequence:03d}.json")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        archive_data = {
            "moduleName": module_name,
            "sequenceNumber": sequence,
            "archiveDate": datetime.now().isoformat(),
            "conversationHistory": history,
            "totalMessages": len(history)
        }
        return safe_json_dump(archive_data, path)

    def get_campaign_summaries(self, session_id: str, module_name: Optional[str] = None) -> List[Dict[str, Any]]:
        manager = self._get_session_manager(session_id)
        summaries_dir = manager.get_path("modules/campaign_summaries")
        summaries = []
        if os.path.exists(summaries_dir):
            import glob
            if module_name:
                pattern = os.path.join(summaries_dir, f"{module_name}_summary_*.json")
            else:
                pattern = os.path.join(summaries_dir, "*.json")
            
            summary_files = glob.glob(pattern)
            # Sort by sequence number if possible
            def extract_seq(f):
                import re
                m = re.search(r'_(\d+)\.json$', f)
                return int(m.group(1)) if m else 0
            
            summary_files.sort(key=extract_seq)
            
            for path in summary_files:
                data = safe_json_load(path)
                if data:
                    summaries.append(data)
        return summaries

    def save_campaign_summary(self, session_id: str, module_name: str, sequence: int, data: Dict[str, Any]) -> bool:
        manager = self._get_session_manager(session_id)
        path = manager.get_path(f"modules/campaign_summaries/{module_name}_summary_{sequence}.json")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        return safe_json_dump(data, path)

    def get_campaign_data(self, session_id: str) -> Optional[Dict[str, Any]]:
        manager = self._get_session_manager(session_id)
        path = manager.get_path("modules/campaign.json")
        return safe_json_load(path)

    def get_player_storage(self, session_id: str) -> Dict[str, Any]:
        manager = self._get_session_manager(session_id)
        path = manager.get_path("player_storage.json")
        return safe_json_load(path) or {"version": "1.0.0", "playerStorage": []}

    def get_pacing_state(self, session_id: str) -> Optional[Dict[str, Any]]:
        manager = self._get_session_manager(session_id)
        path = manager.get_path("pacing_state.json")
        return safe_json_load(path)

    def save_pacing_state(self, session_id: str, data: Dict[str, Any]) -> bool:
        manager = self._get_session_manager(session_id)
        path = manager.get_path("pacing_state.json")
        return safe_json_dump(data, path)
