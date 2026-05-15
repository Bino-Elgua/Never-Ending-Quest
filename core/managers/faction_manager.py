import random
from typing import List, Dict, Any
from utils.file_operations import safe_read_json, safe_write_json
from utils.enhanced_logger import debug, info

class Faction:
    def __init__(self, name: str, alignment: str, goals: List[str], influence: int = 50):
        self.name = name
        self.alignment = alignment
        self.goals = goals
        self.influence = influence # 0-100
        self.active_plots = []

class FactionManager:
    """Simulates background world events and faction dynamics."""
    
    def __init__(self, session_id: str):
        self.session_id = session_id
        self.factions_file = f"sessions/{session_id}/world/factions.json"
        self._load_factions()

    def _load_factions(self):
        data = safe_read_json(self.factions_file)
        if not data:
            self.factions = self._generate_default_factions()
            self._save_factions()
        else:
            self.factions = data

    def _generate_default_factions(self) -> List[Dict[str, Any]]:
        return [
            {
                "name": "The Iron Vanguard",
                "alignment": "Lawful Neutral",
                "goals": ["Maintain order", "Secure the borders"],
                "influence": 60,
                "wealth": 80,
                "disposition": "Neutral"
            },
            {
                "name": "The Crimson Circle",
                "alignment": "Chaotic Evil",
                "goals": ["Destabilize the kingdom", "Summon eldritch horrors"],
                "influence": 30,
                "wealth": 40,
                "disposition": "Hostile"
            },
            {
                "name": "The Gilded Hand",
                "alignment": "Neutral Evil",
                "goals": ["Control the economy", "Monopolize magical artifacts"],
                "influence": 70,
                "wealth": 95,
                "disposition": "Greedy"
            }
        ]

    def _save_factions(self):
        os.makedirs(os.path.dirname(self.factions_file), exist_ok=True)
        safe_write_json(self.factions_file, self.factions)

    def simulate_world_tick(self):
        """Advance world state by one 'tick' and update world_state.json."""
        info(f"WORLD_SIM: Simulating world tick for session {self.session_id}")
        major_events = []
        for faction in self.factions:
            delta = random.randint(-5, 5)
            faction['influence'] = max(0, min(100, faction['influence'] + delta))
            
            if random.random() > 0.8:
                faction['influence'] += 10
                major_events.append(f"{faction['name']} achieved a strategic objective.")

        self._save_factions()
        
        # Update session world_state
        state_file = f"sessions/{self.session_id}/world/world_state.json"
        world_state = safe_read_json(state_file) or {"major_decisions": [], "faction_events": []}
        world_state["faction_events"].extend(major_events)
        safe_write_json(state_file, world_state)
        
        return self.factions

    def get_world_ripples(self) -> List[str]:
        """Convert current faction states into narrative 'ripples' for the DM."""
        ripples = []
        for faction in self.factions:
            if faction['influence'] > 80:
                ripples.append(f"{faction['name']} has become a dominant force in the region.")
            elif faction['influence'] < 20:
                ripples.append(f"{faction['name']} is collapsing, creating a power vacuum.")
        return ripples
