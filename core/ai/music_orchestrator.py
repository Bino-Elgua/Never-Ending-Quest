class MusicOrchestrator:
    """Analyzes narrative sentiment to determine the background music mood."""
    
    MOOD_MAPPINGS = {
        "battle": ["combat", "fight", "attack", "blood", "steel", "sword"],
        "stealth": ["shadow", "quiet", "creep", "hidden", "sneak", "darkness"],
        "mystery": ["strange", "ancient", "arcane", "glowing", "flicker", "old"],
        "town": ["market", "tavern", "inn", "cheerful", "bustle", "crowd"],
        "danger": ["trap", "lava", "poison", "ominous", "threat", "risk"]
    }

    def determine_mood(self, narration_text: str) -> str:
        """Heuristic-based mood detection from narration."""
        text = narration_text.lower()
        
        for mood, keywords in self.MOOD_MAPPINGS.items():
            if any(kw in text for kw in keywords):
                return mood
                
        return "ambient" # Default exploration mood
