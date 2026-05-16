from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional

class DatabaseService(ABC):
    """Base interface for state management in NeverEndingQuest."""
    
    @abstractmethod
    def get_party_tracker(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Retrieve the party tracker for a specific session."""
        pass
        
    @abstractmethod
    def save_party_tracker(self, session_id: str, data: Dict[str, Any]) -> bool:
        """Save the party tracker for a specific session."""
        pass
        
    @abstractmethod
    def get_character(self, session_id: str, character_name: str) -> Optional[Dict[str, Any]]:
        """Retrieve a character's data for a specific session."""
        pass
        
    @abstractmethod
    def save_character(self, session_id: str, character_name: str, data: Dict[str, Any]) -> bool:
        """Save a character's data for a specific session."""
        pass
        
    @abstractmethod
    def get_current_location(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Retrieve the current location for a specific session."""
        pass
        
    @abstractmethod
    def save_current_location(self, session_id: str, data: Dict[str, Any]) -> bool:
        """Save the current location for a specific session."""
        pass
        
    @abstractmethod
    def get_conversation_history(self, session_id: str) -> List[Dict[str, Any]]:
        """Retrieve the conversation history for a specific session."""
        pass
        
    @abstractmethod
    def save_conversation_history(self, session_id: str, history: List[Dict[str, Any]]) -> bool:
        """Save the conversation history for a specific session."""
        pass

    @abstractmethod
    def archive_conversation_history(self, session_id: str, module_name: str, sequence: int, history: List[Dict[str, Any]]) -> bool:
        """Archive a full conversation history for a module."""
        pass

    @abstractmethod
    def get_campaign_summaries(self, session_id: str, module_name: Optional[str] = None) -> List[Dict[str, Any]]:
        """Retrieve campaign summaries, optionally filtered by module."""
        pass

    @abstractmethod
    def save_campaign_summary(self, session_id: str, module_name: str, sequence: int, data: Dict[str, Any]) -> bool:
        """Save a campaign summary for a specific module and sequence."""
        pass

    @abstractmethod
    def get_campaign_data(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Retrieve general campaign metadata."""
        pass

    @abstractmethod
    def get_player_storage(self, session_id: str) -> Dict[str, Any]:
        """Retrieve player storage data."""
        pass

    @abstractmethod
    def get_pacing_state(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Retrieve the pacing conductor state (combat turn tracking)."""
        pass

    @abstractmethod
    def save_pacing_state(self, session_id: str, data: Dict[str, Any]) -> bool:
        """Save the pacing conductor state."""
        pass
