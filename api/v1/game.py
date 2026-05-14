from flask import Blueprint, jsonify, request
import os
import json
from utils.file_operations import safe_read_json
from utils.module_path_manager import ModulePathManager

game_bp = Blueprint('game', __name__)

@game_bp.route('/status', methods=['GET'])
def get_game_status():
    """Get the current state of the game (party, location, etc.)"""
    party_tracker = safe_read_json("party_tracker.json")
    if not party_tracker:
        return jsonify({"success": False, "message": "Game not initialized"}), 404
        
    # Get current character data
    characters = []
    module_name = party_tracker.get("module", "").replace(" ", "_")
    path_manager = ModulePathManager(module_name)
    
    for member_name in party_tracker.get("partyMembers", []):
        from updates.update_character_info import normalize_character_name
        norm_name = normalize_character_name(member_name)
        char_data = safe_read_json(path_manager.get_character_path(norm_name))
        if char_data:
            characters.append(char_data)
            
    # Get current location data
    current_location = safe_read_json("current_location.json")
    
    return jsonify({
        "party_tracker": party_tracker,
        "characters": characters,
        "current_location": current_location,
        "module": module_name
    })

@game_bp.route('/chat-history', methods=['GET'])
def get_chat_history():
    """Get the recent conversation history"""
    history = safe_read_json("modules/conversation_history/conversation_history.json")
    if not history:
        return jsonify([])
    
    return jsonify(history)

@game_bp.route('/combat-status', methods=['GET'])
def get_combat_status():
    """Get the current state of combat (turn, combatants, grid)"""
    # In a real scenario, this would fetch from core.managers.combat_manager
    # For now, we return a mock state to demonstrate the mobile grid
    return jsonify({
        "turn": 1,
        "combatants": [
            {
                "id": "p1",
                "name": "Valerius",
                "hp": 24,
                "maxHp": 30,
                "position": [2, 3],
                "isPlayer": True
            },
            {
                "id": "m1",
                "name": "Goblin Scout",
                "hp": 7,
                "maxHp": 7,
                "position": [4, 5],
                "isPlayer": False
            }
        ],
        "grid": {"width": 10, "height": 10}
    })

@game_bp.route('/action', methods=['POST'])
def perform_action():
    """
    Perform a game action. 
    Note: Real-time interactions should still use WebSockets for streaming.
    This is for direct, non-streaming actions.
    """
    data = request.get_json() or {}
    user_input = data.get('input')
    
    if not user_input:
        return jsonify({"success": False, "message": "No input provided"}), 400
        
    # Implementation here would involve calling the game loop logic
    # similar to how main.py or web_interface.py does it.
    # For now, we'll suggest using the WebSocket for game turns.
    return jsonify({
        "success": True, 
        "message": "Action received. Please use WebSocket for real-time game turns.",
        "input": user_input
    })
