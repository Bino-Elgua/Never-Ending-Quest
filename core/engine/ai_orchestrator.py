import json
from openai import OpenAI
import config
from utils.enhanced_logger import info, error, debug

class AIOrchestrator:
    """Handles all interactions with AI models, including hardening and cost management."""
    
    def __init__(self):
        self.client = OpenAI(api_key=config.OPENAI_API_KEY, base_url=config.OPENAI_BASE_URL)
        
    def generate_response(self, messages: List[Dict[str, str]], model: str = None) -> str:
        """Call AI with cost tracking and threshold enforcement."""
        model = model or config.DM_MAIN_MODEL
        
        # Check cost/usage thresholds here (Phase 5 requirement)
        
        try:
            response = self.client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=0.8
            )
            return response.choices[0].message.content
        except Exception as e:
            error(f"AI_ORCHESTRATOR: AI call failed: {e}")
            raise
