import json
from typing import List, Dict, Any, Optional
from core.database import get_db

class StateManager:
    """Manages session-scoped application state and persistent storage access."""
    
    def __init__(self, session_id: str = "default"):
        self.session_id = session_id
        self.db = get_db()
        
    def get_party_tracker(self) -> Dict[str, Any]:
        return self.db.get_party_tracker(self.session_id) or {}

    def save_party_tracker(self, data: Dict[str, Any]):
        self.db.save_party_tracker(self.session_id, data)

    def get_character(self, name: str) -> Optional[Dict[str, Any]]:
        return self.db.get_character(self.session_id, name)

    def save_character(self, name: str, data: Dict[str, Any]):
        self.db.save_character(self.session_id, name, data)

    def get_conversation_history(self) -> List[Dict[str, Any]]:
        return self.db.get_conversation_history(self.session_id)

    def save_conversation_history(self, history: List[Dict[str, Any]]):
        self.db.save_conversation_history(self.session_id, history)
