import os
import shutil
from typing import Dict, Any, Optional
from utils.encoding_utils import safe_json_load, safe_json_dump
from utils.enhanced_logger import debug, info, error

class SessionManager:
    """Manages multi-player session isolation and state persistence."""
    
    BASE_SESSIONS_DIR = "sessions"

    def __init__(self, session_id: str):
        self.session_id = session_id
        self.session_dir = os.path.join(self.BASE_SESSIONS_DIR, session_id)
        self._ensure_session_dirs()

    def _ensure_session_dirs(self):
        """Create isolated directories for this session if they don't exist."""
        required_dirs = [
            self.session_dir,
            os.path.join(self.session_dir, "modules"),
            os.path.join(self.session_dir, "modules/conversation_history"),
            os.path.join(self.session_dir, "modules/campaign_summaries"),
            os.path.join(self.session_dir, "modules/campaign_archives"),
            os.path.join(self.session_dir, "combat_logs"),
        ]
        for d in required_dirs:
            os.makedirs(d, exist_ok=True)

    def get_path(self, relative_path: str) -> str:
        """Returns the session-scoped path for a given global path."""
        # Map known global paths to session-scoped ones
        if relative_path == "party_tracker.json":
            return os.path.join(self.session_dir, "party_tracker.json")
        if relative_path == "current_location.json":
            return os.path.join(self.session_dir, "current_location.json")
        if relative_path.startswith("modules/"):
            return os.path.join(self.session_dir, relative_path)
        if relative_path.startswith("combat_logs/"):
            return os.path.join(self.session_dir, relative_path)
            
        return os.path.join(self.session_dir, relative_path)

    def initialize_session(self, template_module: str = "The_Thornwood_Watch"):
        """Initialize a new session with template data if empty."""
        party_file = self.get_path("party_tracker.json")
        if not os.path.exists(party_file):
            debug(f"SESSION: Initializing session {self.session_id} from default templates")
            # In a production system, we'd copy from a 'templates' directory
            # For now, if the global ones exist, we can use them as a starting point 
            # or create defaults.
            default_party = {
                "partyMembers": ["Valerius"],
                "module": template_module,
                "worldConditions": {
                    "currentLocation": "Unknown",
                    "currentArea": "Unknown",
                    "time": "Dawn"
                }
            }
            safe_json_dump(default_party, party_file)

    @staticmethod
    def list_active_sessions():
        """List all sessions currently on disk."""
        if not os.path.exists(SessionManager.BASE_SESSIONS_DIR):
            return []
        return os.listdir(SessionManager.BASE_SESSIONS_DIR)
