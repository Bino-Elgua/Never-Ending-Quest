import os
from openai import OpenAI
import config
from utils.enhanced_logger import info, error

class PortraitEvolver:
    """Updates NPC portraits based on character status and events."""

    def __init__(self):
        self.client = OpenAI(api_key=config.OPENAI_API_KEY)

    def evolve_portrait(self, npc_data, status_description):
        """
        Generates a new portrait prompt based on current NPC stats and status.
        """
        npc_name = npc_data.get('name', 'Unknown Hero')
        npc_class = npc_data.get('class', 'Warrior')
        npc_race = npc_data.get('race', 'Human')
        
        prompt = (
            f"A high-quality fantasy character portrait of {npc_name}, a {npc_race} {npc_class}. "
            f"Current state: {status_description}. "
            f"Style: Digital fantasy painting, detailed, cinematic lighting, "
            f"consistent with a dark fantasy setting."
        )

        try:
            info(f"PORTRAIT_EVOLVE: Evolving {npc_name} ({status_description})...")
            response = self.client.images.generate(
                model="dall-e-3",
                prompt=prompt,
                size="1024x1024",
                n=1,
            )
            return response.data[0].url
        except Exception as e:
            error(f"PORTRAIT_EVOLVE: Error: {e}")
            return None
