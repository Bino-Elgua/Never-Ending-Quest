from typing import List, Dict, Any, Optional
from utils.enhanced_logger import debug, info
from core.database import get_db

class PacingConductor:
    """
    Handles turn management, initiative, and authority in combat/multiplayer.
    Ensures synchronized state across all connected clients.
    """

    def __init__(self, session_id: str):
        self.session_id = session_id
        self.db = get_db()
        self._load_state()

    def _load_state(self):
        state = self.db.get_pacing_state(self.session_id)
        if state:
            self.active_combatant_index = state.get('active_combatant_index', 0)
            self.turn_number = state.get('turn_number', 1)
            self.initiative_order = state.get('initiative_order', [])
            self.is_combat_active = state.get('is_combat_active', False)
        else:
            self.active_combatant_index = 0
            self.turn_number = 1
            self.initiative_order = []
            self.is_combat_active = False

    def _save_state(self):
        state = {
            'active_combatant_index': self.active_combatant_index,
            'turn_number': self.turn_number,
            'initiative_order': self.initiative_order,
            'is_combat_active': self.is_combat_active
        }
        self.db.save_pacing_state(self.session_id, state)

    def start_combat(self, combatants: List[Dict[str, Any]]):
        """Initialize combat with sorted initiative order."""
        self.initiative_order = sorted(
            combatants, 
            key=lambda x: x.get('initiative', 0), 
            reverse=True
        )
        self.active_combatant_index = 0
        self.turn_number = 1
        self.is_combat_active = True
        self._save_state()
        info(f"PACING: Combat started for session {self.session_id}. Order: {[c['name'] for c in self.initiative_order]}")

    def next_turn(self) -> Dict[str, Any]:
        """Advance to the next combatant's turn."""
        if not self.is_combat_active:
            return {"error": "Combat not active"}

        self.active_combatant_index += 1
        if self.active_combatant_index >= len(self.initiative_order):
            self.active_combatant_index = 0
            self.turn_number += 1
            info(f"PACING: New Round {self.turn_number} for session {self.session_id}")

        active = self.get_current_combatant()
        self._save_state()
        debug(f"PACING: It is now {active['name']}'s turn (Round {self.turn_number})")
        return {
            "active_combatant": active,
            "turn": self.turn_number,
            "index": self.active_combatant_index
        }

    def get_current_combatant(self) -> Dict[str, Any]:
        """Get the combatant whose turn it currently is."""
        if not self.initiative_order:
            return {"name": "None"}
        return self.initiative_order[self.active_combatant_index]

    def end_combat(self):
        """End the combat session."""
        self.is_combat_active = False
        self.initiative_order = []
        self._save_state()
        info(f"PACING: Combat ended for session {self.session_id}")
