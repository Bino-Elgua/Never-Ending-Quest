import json
import re
from utils.enhanced_logger import debug, warning, error

class LLMHardenService:
    """
    Service to validate and repair LLM outputs to ensure they adhere to 
    game schemas and SRD rules.
    """
    
    REQUIRED_FIELDS = ['narration', 'actions']
    VALID_ACTIONS = [
        'updateCharacter', 'updateNPC', 'updateParty', 'updateLocation',
        'updateWorldTime', 'createEncounter', 'transitionLocation', 
        'plotUpdate', 'levelUp'
    ]

    @staticmethod
    def validate_and_repair(response_text):
        """
        Parses the LLM response, validates fields, and attempts repairs.
        """
        try:
            # Strip markdown code blocks if present
            clean_text = re.sub(r'```json\s*|\s*```', '', response_text).strip()
            data = json.loads(clean_text)
            
            # 1. Ensure required fields
            for field in LLMHardenService.REQUIRED_FIELDS:
                if field not in data:
                    if field == 'actions':
                        data['actions'] = []
                    elif field == 'narration':
                        data['narration'] = "The DM is at a loss for words..."
                        
            # 2. Sanitize actions
            sanitized_actions = []
            for action in data.get('actions', []):
                if isinstance(action, dict) and action.get('action') in LLMHardenService.VALID_ACTIONS:
                    sanitized_actions.append(action)
                else:
                    warning(f"HARDEN: Removed invalid action: {action}")
            
            data['actions'] = sanitized_actions
            
            # 3. Rules Warden (Simplified SRD check)
            # Example: Prevent impossible HP updates or level jumps
            for action in data['actions']:
                if action['action'] == 'updateCharacter':
                    params = action.get('parameters', {})
                    if 'hp' in params and params['hp'] < 0:
                        params['hp'] = 0
                    if 'level' in params and params['level'] > 20:
                        params['level'] = 20
            
            return data, True
            
        except json.JSONDecodeError as e:
            error(f"HARDEN: AI produced invalid JSON: {e}")
            return {
                "narration": "The weave of magic flickers... (The AI response was malformed)",
                "actions": []
            }, False
        except Exception as e:
            error(f"HARDEN: Unexpected error in validation: {e}")
            return None, False

def harden_dm_output(response_text):
    """Convenience wrapper for the hardening service"""
    return LLMHardenService.validate_and_repair(response_text)
