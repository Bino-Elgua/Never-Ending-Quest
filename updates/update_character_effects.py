# SPDX-FileCopyrightText: 2024 MoonlightByte
# SPDX-License-Identifier: Fair-Source-1.0
# License: See LICENSE file in the repository root
# This software is subject to the terms of the Fair Source License.

"""
AI-driven temporary effects tracking system that runs parallel to character updates.
Tracks temporary modifiers and automatically reverses them when expired.
"""

import json
import os
import uuid
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List
from utils.enhanced_logger import debug, info, warning, error
from utils.encoding_utils import safe_json_load, safe_json_dump
from utils.file_operations import safe_read_json, safe_write_json
from utils.module_path_manager import ModulePathManager
from updates.update_character_info import normalize_character_name
from openai import OpenAI
import config
from core.database import get_db

# Set up logging
from utils.enhanced_logger import set_script_name
set_script_name(os.path.basename(__file__))

# Initialize OpenAI client
client = OpenAI(api_key=config.OPENAI_API_KEY)

def get_current_game_time(session_id="default") -> datetime:
    """Get current game time from DB as datetime."""
    db = get_db()
    party_data = db.get_party_tracker(session_id)
    if not party_data or "worldConditions" not in party_data:
        warning("Failed to get game time from party tracker", category="effects_tracking")
        return datetime(2000, 1, 1)
    
    world = party_data["worldConditions"]
    day = world.get("day", 0)
    time_str = world.get("time", "00:00:00")
    
    time_parts = time_str.split(":")
    hour = int(time_parts[0])
    minute = int(time_parts[1]) if len(time_parts) > 1 else 0
    second = int(time_parts[2]) if len(time_parts) > 2 else 0
    
    total_days = day
    # Simple year/month/day conversion for tracking
    base_date = datetime(2000, 1, 1)
    game_datetime = base_date + timedelta(days=total_days, hours=hour, minutes=minute, seconds=second)
    
    return game_datetime

def get_effects_file_path(session_id="default") -> str:
    """Get the path to the effects tracker file, scoped to session."""
    return f"modules/effects_tracker_{session_id}.json"

def load_effects_tracker(session_id="default") -> Dict[str, Any]:
    """Load the effects tracker file for session, creating it if it doesn't exist."""
    file_path = get_effects_file_path(session_id)
    
    if not os.path.exists(file_path):
        initial_data = {
            "version": "1.0",
            "lastUpdated": datetime.now().isoformat(),
            "characters": {},
            "metadata": {"description": f"Tracks temporary effects for session {session_id}"}
        }
        safe_write_json(file_path, initial_data)
        return initial_data
    
    data = safe_read_json(file_path)
    return data if data else {"characters": {}}

def save_effects_tracker(data: Dict[str, Any], session_id="default") -> bool:
    """Save the effects tracker file for session."""
    file_path = get_effects_file_path(session_id)
    data["lastUpdated"] = datetime.now().isoformat()
    return safe_write_json(file_path, data)

def analyze_effect_with_ai(character_name: str, change_description: str, session_id="default") -> Optional[Dict[str, Any]]:
    """Use AI to analyze if a change is a trackable temporary effect."""
    db = get_db()
    character_stats = {}
    char_data = db.get_character(session_id, character_name)
    if char_data and 'abilities' in char_data:
        character_stats = char_data['abilities']
    
    stats_info = f"\nCharacter's current ability scores: STR {character_stats.get('strength', 10)}, DEX {character_stats.get('dexterity', 10)}, CON {character_stats.get('constitution', 10)}, INT {character_stats.get('intelligence', 10)}, WIS {character_stats.get('wisdom', 10)}, CHA {character_stats.get('charisma', 10)}" if character_stats else ""
    
    prompt = f"""You are an effects tracking AI for a 5th edition fantasy RPG. Analyze this character update to determine if it's a temporary effect that should be tracked.

Character: {character_name}{stats_info}
Update: {change_description}

Determine if this is a TEMPORARY effect that will expire. Track temporary effects with durations of 1 minute or longer.
Do NOT track instant effects, permanent changes, or effects lasting less than 1 minute (including round-based effects).
IMPORTANT: Convert any round-based durations to minutes (10 rounds = 1 minute) if the effect should persist.

Return JSON with this exact structure:
{{
  "should_track": true/false,
  "effect": {{
    "stat": "hitPoints|maxHitPoints|strength|dexterity|constitution|intelligence|wisdom|charisma|armorClass|other",
    "value": numeric_modifier (positive or negative),
    "source": "brief description of source",
    "duration_type": "hours|days|until_rest|special",
    "duration_value": number or "long_rest"/"short_rest",
    "description": "full effect description",
    "affects_max": true/false
  }}
}}
"""

    try:
        response = client.chat.completions.create(
            model=config.DM_EFFECTS_MODEL if hasattr(config, 'DM_EFFECTS_MODEL') else config.DM_MAIN_MODEL,
            temperature=0.3,
            messages=[
                {"role": "system", "content": prompt},
                {"role": "user", "content": f"Analyze this update: {change_description}"}
            ]
        )
        
        response_text = response.choices[0].message.content.strip()
        if response_text.startswith("```json"): response_text = response_text[7:]
        if response_text.endswith("```"): response_text = response_text[:-3]
        
        return json.loads(response_text.strip())
    except Exception as e:
        error(f"Failed to analyze effect with AI: {str(e)}")
        return None

def calculate_expiration(duration_type: str, duration_value: Any, session_id="default") -> Optional[str]:
    """Calculate when an effect expires based on duration."""
    now = get_current_game_time(session_id)
    if duration_type == "hours":
        try: return (now + timedelta(hours=float(duration_value))).isoformat()
        except: return None
    elif duration_type == "days":
        try: return (now + timedelta(days=int(duration_value))).isoformat()
        except: return None
    elif duration_type == "until_rest":
        return duration_value
    return None

def add_effect(character_name: str, effect_info: Dict[str, Any], session_id="default") -> bool:
    """Add a new effect to the tracker."""
    tracker = load_effects_tracker(session_id)
    normalized_name = normalize_character_name(character_name)
    
    if normalized_name not in tracker["characters"]:
        tracker["characters"][normalized_name] = {"modifiers": []}
    
    effect_id = str(uuid.uuid4())[:8]
    game_time = get_current_game_time(session_id)
    
    effect_entry = {
        "id": effect_id,
        "stat": effect_info["stat"],
        "value": effect_info["value"],
        "source": effect_info["source"],
        "description": effect_info["description"],
        "applied_at": game_time.isoformat(),
        "duration_type": effect_info["duration_type"],
        "duration_value": effect_info["duration_value"]
    }
    
    if "affects_max" in effect_info: effect_entry["affects_max"] = effect_info["affects_max"]
    
    expiration = calculate_expiration(effect_info["duration_type"], effect_info["duration_value"], session_id)
    if expiration: effect_entry["expires_at"] = expiration
    
    tracker["characters"][normalized_name]["modifiers"].append(effect_entry)
    return save_effects_tracker(tracker, session_id)

def check_and_apply_expirations(session_id="default") -> List[Dict[str, Any]]:
    """Check for expired effects and generate reversal actions."""
    tracker = load_effects_tracker(session_id)
    now = get_current_game_time(session_id)
    reversals = []
    
    for character_name, char_data in tracker["characters"].items():
        if "modifiers" not in char_data: continue
        
        active_modifiers = []
        for modifier in char_data["modifiers"]:
            expired = False
            if "expires_at" in modifier and modifier["expires_at"] not in ["long_rest", "short_rest", "special"]:
                try:
                    if now >= datetime.fromisoformat(modifier["expires_at"]):
                        expired = True
                except: pass
            
            if expired:
                reversals.append({"character": character_name, "description": f"Effect '{modifier['source']}' expires", "modifier": modifier})
            else:
                active_modifiers.append(modifier)
        
        char_data["modifiers"] = active_modifiers
    
    if reversals: save_effects_tracker(tracker, session_id)
    return reversals

def clear_rest_effects(character_name: str, rest_type: str, session_id="default") -> List[Dict[str, Any]]:
    """Clear effects that expire on rest."""
    tracker = load_effects_tracker(session_id)
    reversals = []
    normalized_name = normalize_character_name(character_name)
    
    if normalized_name not in tracker["characters"]: return reversals
    
    char_data = tracker["characters"][normalized_name]
    active_modifiers = []
    
    for modifier in char_data["modifiers"]:
        should_clear = False
        if "expires_at" in modifier:
            if rest_type == "long_rest" and modifier["expires_at"] in ["long_rest", "short_rest"]: should_clear = True
            elif rest_type == "short_rest" and modifier["expires_at"] == "short_rest": should_clear = True
        
        if should_clear:
            reversals.append({"character": character_name, "description": f"Effect '{modifier['source']}' expires after {rest_type}", "modifier": modifier})
        else:
            active_modifiers.append(modifier)
    
    char_data["modifiers"] = active_modifiers
    save_effects_tracker(tracker, session_id)
    return reversals

def update_character_effects(character_name: str, change_description: str, session_id="default") -> bool:
    """Main entry point for effects tracking."""
    change_lower = change_description.lower()
    if any(phrase in change_lower for phrase in ["short rest", "long rest", "takes a rest", "take a rest"]):
        rest_type = "long_rest" if "long rest" in change_lower else "short_rest"
        rest_reversals = clear_rest_effects(character_name, rest_type, session_id)
        if rest_reversals:
            from updates.update_character_info import update_character_info
            for reversal in rest_reversals:
                update_character_info(reversal["character"], reversal["description"], session_id=session_id)
    
    analysis = analyze_effect_with_ai(character_name, change_description, session_id)
    if analysis and analysis["should_track"]:
        return add_effect(character_name, analysis["effect"], session_id)
    return True
