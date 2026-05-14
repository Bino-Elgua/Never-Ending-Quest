import requests
import json
import model_config

class OpenRouterClient:
    def __init__(self, api_key=None):
        self.api_key = api_key or model_config.OPENROUTER_API_KEY
        self.base_url = "https://openrouter.ai/api/v1/chat/completions"

    def chat(self, messages, model=None, temperature=0.7, max_tokens=None):
        if not model_config.USE_OPENROUTER:
            return None # Fallback to original provider
            
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "HTTP-Referer": "https://github.com/MoonlightByte/NeverEndingQuest",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": model or model_config.MODEL_PRO,
            "messages": messages,
            "temperature": temperature,
        }
        
        if max_tokens:
            payload["max_tokens"] = max_tokens

        try:
            response = requests.post(self.base_url, headers=headers, data=json.dumps(payload))
            response.raise_for_status()
            result = response.json()
            return result['choices'][0]['message']['content']
        except Exception as e:
            print(f"[OPENROUTER] Error: {e}")
            return None

def get_smart_model(task_type):
    """
    Returns the appropriate OpenRouter model based on the task type.
    """
    if task_type == "narration" or task_type == "plot":
        return model_config.MODEL_ULTRA
    elif task_type == "combat" or task_type == "mechanics":
        return model_config.MODEL_PRO
    elif task_type == "summary" or task_type == "state":
        return model_config.MODEL_FLASH
    else:
        return model_config.MODEL_CHEAP
