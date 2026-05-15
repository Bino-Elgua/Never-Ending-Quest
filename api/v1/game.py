from flask import Blueprint, jsonify, request
import os
import json
import asyncio
from utils.file_operations import safe_read_json
from utils.module_path_manager import ModulePathManager
from core.managers.session_manager import SessionManager
from core.managers.campaign_manager import CampaignManager
from core.managers.game_manager import GameManager

game_bp = Blueprint('game', __name__)

# Registry for session-specific game managers
game_sessions = {}

def get_game_manager(session_id):
    if session_id not in game_sessions:
        game_sessions[session_id] = GameManager(session_id)
        game_sessions[session_id].session.initialize_session()
    return game_sessions[session_id]

@game_bp.route('/<session_id>/status', methods=['GET'])
def get_game_status(session_id):
    """Get the current state of the game scoped to a session"""
    session = SessionManager(session_id)
    party_file = session.get_path("party_tracker.json")
    
    party_tracker = safe_read_json(party_file)
    if not party_tracker:
        return jsonify({"success": False, "message": f"Session {session_id} not initialized"}), 404
        
    # Get current character data
    characters = []
    module_name = party_tracker.get("module", "").replace(" ", "_")
    path_manager = ModulePathManager(module_name)
    
    for member_name in party_tracker.get("partyMembers", []):
        from updates.update_character_info import normalize_character_name
        norm_name = normalize_character_name(member_name)
        char_data = safe_read_json(session.get_path(path_manager.get_character_path(norm_name)))
        if char_data:
            characters.append(char_data)
            
    # Get current location data
    current_location = safe_read_json(session.get_path("current_location.json"))
    
    return jsonify({
        "party_tracker": party_tracker,
        "characters": characters,
        "current_location": current_location,
        "module": module_name
    })

@game_bp.route('/<session_id>/chat-history', methods=['GET'])
def get_chat_history(session_id):
    """Get the conversation history for a specific session"""
    session = SessionManager(session_id)
    history_file = session.get_path("modules/conversation_history/conversation_history.json")
    history = safe_read_json(history_file)
    if not history:
        return jsonify([])
    
    return jsonify(history)

@game_bp.route('/<session_id>/action', methods=['POST'])
def perform_action(session_id):
    """Process a game action within a session context"""
    data = request.get_json() or {}
    user_input = data.get('input')
    username = data.get('username', 'Mobile User')
    
    if not user_input:
        return jsonify({"success": False, "message": "No input provided"}), 400
        
    # Get manager for this session
    manager = get_game_manager(session_id)
    
    # Process AI response synchronously for the REST API
    try:
        # Create a new event loop for this request
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        response = loop.run_until_complete(manager.process_user_input(user_input, username))
        loop.close()
        
        return jsonify({
            "success": True, 
            "message": "Action processed",
            "response": response
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "message": f"AI processing failed: {str(e)}"
        }), 500

@game_bp.route('/<session_id>/combat-status', methods=['GET'])
def get_combat_status(session_id):
    """Get the current state of combat for a specific session"""
    # In a full implementation, this would fetch from a persistent Conductor state
    return jsonify({
        "session_id": session_id,
        "turn": 1,
        "combatants": [
            {"id": "p1", "name": "Valerius", "hp": 24, "maxHp": 30, "position": [2, 3], "isPlayer": True}
        ]
    })

# --- DM COPILOT ENDPOINTS ---

@game_bp.route('/<session_id>/copilot/whisper', methods=['POST'])
def copilot_whisper(session_id):
    """DM sends a hidden instruction to the AI for the next turn."""
    data = request.get_json() or {}
    instruction = data.get('instruction')
    
    if not instruction:
        return jsonify({"success": False, "message": "No instruction provided"}), 400
        
    # In full implementation, this would be saved in the GameManager instance
    # for the next AI generation call.
    return jsonify({"success": True, "message": "Instruction queued for AI."})

@game_bp.route('/<session_id>/copilot/trigger', methods=['POST'])
def copilot_trigger(session_id):
    """DM manually triggers an event (Ambush, Loot, Twist)."""
    data = request.get_json() or {}
    event_type = data.get('event')
    
    # Force the AI to react to this event in the next response
    return jsonify({"success": True, "message": f"Trigger {event_type} activated."})
