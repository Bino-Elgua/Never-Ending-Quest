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

from core.database import get_db

@game_bp.route('/<session_id>/status', methods=['GET'])
def get_game_status(session_id):
    """Get the current state of the game scoped to a session"""
    db = get_db()
    party_tracker = db.get_party_tracker(session_id)
    if not party_tracker:
        return jsonify({"success": False, "message": f"Session {session_id} not initialized"}), 404
        
    # Get current character data
    characters = []
    for member_name in party_tracker.get("partyMembers", []):
        from updates.update_character_info import normalize_character_name
        norm_name = normalize_character_name(member_name)
        char_data = db.get_character(session_id, norm_name)
        if char_data:
            characters.append(char_data)
            
    # Get current location data
    current_location = db.get_current_location(session_id)
    
    return jsonify({
        "party_tracker": party_tracker,
        "characters": characters,
        "current_location": current_location,
        "module": party_tracker.get("module", "Unknown")
    })

@game_bp.route('/<session_id>/chat-history', methods=['GET'])
def get_chat_history(session_id):
    """Get the conversation history for a specific session"""
    db = get_db()
    history = db.get_conversation_history(session_id)
    return jsonify(history or [])

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

from core.managers.pacing_conductor import PacingConductor

@game_bp.route('/<session_id>/combat-status', methods=['GET'])
def get_combat_status(session_id):
    """Get the current state of combat for a specific session"""
    pacing = PacingConductor(session_id)
    return jsonify({
        "session_id": session_id,
        "turn": pacing.turn_number,
        "active_combatant": pacing.get_current_combatant(),
        "is_active": pacing.is_combat_active,
        "order": pacing.initiative_order
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
