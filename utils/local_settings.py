import json
from pathlib import Path

DEFAULT_SETTINGS = {
    "openai_key": "",
    "openrouter_key": "",
    "use_openrouter": False,
    "image_generation_enabled": True,
    "openai_base_url": ""
}


def load_local_settings(settings_path: str = "local_settings.json") -> dict:
    """Load configuration values from a local settings file."""
    settings_file = Path(settings_path)
    if not settings_file.exists():
        return {}

    try:
        with settings_file.open("r", encoding="utf-8") as f:
            data = json.load(f)
            if isinstance(data, dict):
                return data
    except Exception:
        pass

    return {}


def apply_local_settings_to_config(settings: dict, config_module):
    """Apply local settings into the active config module at runtime."""
    if not settings:
        return

    if settings.get("openai_key"):
        setattr(config_module, "OPENAI_API_KEY", settings["openai_key"])

    if settings.get("openrouter_key"):
        setattr(config_module, "OPENROUTER_API_KEY", settings["openrouter_key"])

    if "use_openrouter" in settings:
        setattr(config_module, "USE_OPENROUTER", bool(settings["use_openrouter"]))

    if "image_generation_enabled" in settings:
        setattr(config_module, "IMAGE_GENERATION_ENABLED", bool(settings["image_generation_enabled"]))

    if settings.get("openai_base_url"):
        setattr(config_module, "OPENAI_BASE_URL", settings["openai_base_url"])
