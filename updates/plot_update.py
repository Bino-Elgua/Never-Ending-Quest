# SPDX-FileCopyrightText: 2024 MoonlightByte
# SPDX-License-Identifier: Fair-Source-1.0
# License: See LICENSE file in the repository root
# This software is subject to the terms of the Fair Source License.

import json
from jsonschema import validate, ValidationError
from openai import OpenAI
import time

# Import OpenAI usage tracking (safe - won't break if fails)
try:
    from utils.openai_usage_tracker import track_response
    USAGE_TRACKING_AVAILABLE = True
except:
    USAGE_TRACKING_AVAILABLE = False
    def track_response(r): pass

# Import model configuration from config.py
from config import OPENAI_API_KEY, PLOT_UPDATE_MODEL
from utils.module_path_manager import ModulePathManager
from utils.file_operations import safe_write_json, safe_read_json
from utils.enhanced_logger import debug, info, warning, error, set_script_name

# Set script name for logging
set_script_name("plot_update")

client = OpenAI(api_key=OPENAI_API_KEY)

# Constants
TEMPERATURE = 0.7

# ANSI escape codes - REMOVED per CLAUDE.md guidelines
# All color codes have been removed to prevent Windows console encoding errors

def load_schema():
    with open("schemas/plot_schema.json", "r") as schema_file:
        return json.load(schema_file)

def update_party_tracker(plot_point_id, new_status, plot_impact, session_id="default"):
    # DEPRECATED: activeQuests tracking has been deprecated in favor of using module_plot.json as the single source of truth
    
    db = get_db()
    party_tracker = db.get_party_tracker(session_id)
    if not party_tracker:
        error(f"FAILURE: Could not read party tracker for session {session_id}", category="database")
        return

    # Use ModulePathManager to get module plot path with current module
    current_module = party_tracker.get("module", "").replace(" ", "_")
    path_manager = ModulePathManager(current_module)
    plot_file_path = path_manager.get_plot_path()

    try:
        plot_info = safe_read_json(plot_file_path)
    except Exception as e:
        error(f"FAILURE: Could not read plot file: {e}", category="file_operations")
        return

    # Still save party_tracker in case other parts were modified
    db.save_party_tracker(session_id, party_tracker)

    debug(f"STATE_CHANGE: Party tracker updated for plot point {plot_point_id}", category="plot_updates")

def update_plot(plot_point_id_param, new_status_param, plot_impact_param, session_id="default", max_retries=3): # Renamed params
    db = get_db()
    try:
        # Use unified module plot file with current module from party tracker
        party_tracker = db.get_party_tracker(session_id)
        current_module = party_tracker.get("module", "").replace(" ", "_") if party_tracker else None
        path_manager = ModulePathManager(current_module)
        plot_file_path = path_manager.get_plot_path()

        plot_info_data = safe_read_json(plot_file_path)
        if not plot_info_data:
            error("FAILURE: Could not read plot file", category="file_operations")
            return None
    except Exception as e:
        error(f"FAILURE: Could not load plot state: {e}", category="plot_updates")
        return None



    plot_schema_data = load_schema() # Renamed variable

    for attempt in range(max_retries):
        prompt_messages = [ # Renamed variable
            {"role": "system", "content": """You are an assistant that updates plot information for a role playing game. Given the current plot information and a plot point ID with its new status and plot impact, return only the updated sections of the JSON. Ensure that the updates adhere to the provided schema. Pay close attention to enum values and required fields. Be sure to update both the 'status' and 'plotImpact' fields for the specified plot point. Return the updated sections as a JSON object with the plot point ID as the key.

Examples:
1. Input: Plot point to update: PP001, New status: in progress, Plot impact: The party has entered the mines and met Old Miner Gregor.
   Output: {"PP001": {"status": "in progress", "plotImpact": "The party has entered the mines and met Old Miner Gregor."}}

2. Input: Plot point to update: PP003, New status: completed, Plot impact: The party successfully navigated the collapsed passage and found signs of recent excavation.
   Output: {"PP003": {"status": "completed", "plotImpact": "The party successfully navigated the collapsed passage and found signs of recent excavation."}}

3. Input: Plot point to update: PP005, New status: in progress, Plot impact: The party is currently battling the Fire Beetles and investigating the strange energy source.
   Output: {"PP005": {"status": "in progress", "plotImpact": "The party is currently battling the Fire Beetles and investigating the strange energy source."}}

4. Input: Plot point to update: SQ001, New status: completed, Plot impact: The party found Old Miner Gregor's lost tools in the Equipment Storage.
   Output: {"PP001": {"sideQuests": [{"id": "SQ001", "status": "completed", "plotImpact": "The party found Old Miner Gregor's lost tools in the Equipment Storage."}]}}

5. Input: Plot point to update: PP011, New status: in progress, Plot impact: The party is exploring the Crystal Cavern and deciphering hidden messages left by the dwarves.
   Output: {"PP011": {"status": "in progress", "plotImpact": "The party is exploring the Crystal Cavern and deciphering hidden messages left by the dwarves."}}"""
            },
            {"role": "user", "content": f"Current plot info: {json.dumps(plot_info_data)}\n\nPlot point to update: {plot_point_id_param}\nNew status: {new_status_param}\nPlot impact: {plot_impact_param}"}
        ]

        response = client.chat.completions.create(
            model=PLOT_UPDATE_MODEL, # Use imported model name
            temperature=TEMPERATURE,
            messages=prompt_messages
        )
        
        # Track usage if available
        if USAGE_TRACKING_AVAILABLE:
            try:
                track_response(response)
            except:
                pass

        ai_response_content = response.choices[0].message.content.strip() # Renamed variable

        try:
            if ai_response_content.startswith("```json"):
                ai_response_content = ai_response_content.split("```json", 1)[1]
            if ai_response_content.endswith("```"):
                ai_response_content = ai_response_content.rsplit("```", 1)[0]
            ai_response_content = ai_response_content.strip()

            updated_sections = json.loads(ai_response_content)

            for current_plot_point_id, updates in updated_sections.items(): # Renamed plot_point_id loop var
                for plot_point_obj in plot_info_data["plotPoints"]: # Renamed plot_point loop var
                    if plot_point_obj["id"] == current_plot_point_id:
                        if "sideQuests" in updates:
                            for updated_quest_item in updates["sideQuests"]: # Renamed updated_quest loop var
                                for quest_item in plot_point_obj.get("sideQuests", []): # Renamed quest loop var, added .get for safety
                                    if quest_item["id"] == updated_quest_item["id"]:
                                        quest_item.update(updated_quest_item)
                                        break
                        else:
                            plot_point_obj.update(updates)
                        break

            validate(instance=plot_info_data, schema=plot_schema_data)

            info(f"SUCCESS: Updated and validated plot info on attempt {attempt + 1}", category="plot_updates")

            if not safe_write_json(plot_file_path, plot_info_data):
                error("FAILURE: Failed to save plot file", category="file_operations")
                return plot_info_data

            update_party_tracker(plot_point_id_param, new_status_param, plot_impact_param, session_id=session_id)

            debug(f"STATE_CHANGE: Plot information updated for plot point {plot_point_id_param}", category="plot_updates")
            
            # Generate player-friendly quest descriptions
            try:
                from utils.quest_player_formatter import format_quests_for_player
                if current_module:
                    debug(f"QUEST_FORMAT: Updating player-friendly quests for module {current_module}", category="plot_updates")
                    format_quests_for_player(current_module)
            except Exception as e:
                warning(f"QUEST_FORMAT: Failed to update player-friendly quests: {e}", category="plot_updates")
            
            return plot_info_data

        except json.JSONDecodeError as e:
            warning(f"VALIDATION: AI response is not valid JSON. Error: {e}", category="ai_processing")
            warning(f"AI_PROCESSING: Attempting to fix malformed JSON response", category="ai_processing")
            try:
                fixed_response = ai_response_content.replace("'", '"')
                fixed_response = fixed_response.replace("True", "true").replace("False", "false")
                updated_sections = json.loads(fixed_response)
                info(f"SUCCESS: Fixed malformed JSON response", category="ai_processing")
                # Re-attempt update logic with fixed_response (simplified for now, original logic was more complex)
                # This might need more robust re-processing if simple replace isn't enough.
                # For this refactor, focusing on model name. The fix attempt is a placeholder.
            except Exception as fix_e: # Catch any error during fixing
                error(f"FAILURE: Failed to fix JSON. Error during fix: {fix_e}. Retrying original response processing", category="ai_processing")
        except ValidationError as e:
            error(f"VALIDATION: Updated info does not match the schema. Error: {e}", category="plot_updates")
            # print(f"{YELLOW}Problematic plot_info_data:{RESET}\n{json.dumps(plot_info_data, indent=2)}") # Log data that failed validation

        if attempt == max_retries - 1:
            error(f"FAILURE: Failed to update plot info after {max_retries} attempts. Returning original plot info", category="plot_updates")
            return plot_info_data # Return original if all retries fail

        time.sleep(1)

    return plot_info_data # Should be unreachable if max_retries leads to return, but good for safety