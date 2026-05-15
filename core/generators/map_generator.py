import os
import requests
from openai import OpenAI
import config
import model_config
from utils.file_operations import safe_read_json, safe_write_json
from utils.enhanced_logger import debug, info, error

class MapGenerator:
    """Generates procedural battle maps using AI."""

    def __init__(self):
        base_url = getattr(config, 'OPENAI_BASE_URL', None)
        self.client = OpenAI(api_key=config.OPENAI_API_KEY, base_url=base_url)

    def generate_battle_map(self, location_description, environment_type="dungeon"):
        """
        Generates a top-down battle map based on narrative description.
        """
        prompt = (
            f"A high-quality, top-down fantasy tabletop RPG battle map of a {environment_type}. "
            f"The map shows: {location_description}. "
            f"Style: Digital painting, grid-aligned, high detail, 2D top-down perspective, "
            f"no characters, realistic lighting."
        )

        try:
            info(f"MAP_GEN: Generating {environment_type} map...")
            response = self.client.images.generate(
                model="dall-e-3",
                prompt=prompt,
                size="1024x1024",
                quality="standard",
                n=1,
            )
            
            image_url = response.data[0].url
            return image_url
            
        except Exception as e:
            error(f"MAP_GEN: Error generating map: {e}")
            return None

    def save_map(self, campaign_id, image_url, map_name="current_battle_map"):
        """Downloads and saves the generated map to the session folder."""
        target_dir = f"sessions/{campaign_id}/maps"
        os.makedirs(target_dir, exist_ok=True)
        
        filepath = os.path.join(target_dir, f"{map_name}.png")
        
        try:
            response = requests.get(image_url)
            if response.status_code == 200:
                with open(filepath, 'wb') as f:
                    f.write(response.content)
                info(f"MAP_GEN: Map saved to {filepath}")
                return filepath
        except Exception as e:
            error(f"MAP_GEN: Failed to save map: {e}")
            
        return None
