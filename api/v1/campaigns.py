from flask import Blueprint, jsonify, request
from core.managers.campaign_manager import CampaignManager
from updates.save_game_manager import SaveGameManager
import os

campaigns_bp = Blueprint('campaigns', __name__)

@campaigns_bp.route('/list', methods=['GET'])
def list_campaigns():
    """List available modules and current campaign context"""
    manager = CampaignManager()
    data = {
        "campaign_name": manager.campaign_data.get('campaignName'),
        "current_module": manager.campaign_data.get('currentModule'),
        "available_modules": manager.campaign_data.get('availableModules', []),
        "completed_modules": manager.campaign_data.get('completedModules', []),
        "hubs": manager.get_available_hubs()
    }
    return jsonify(data)

@campaigns_bp.route('/saves', methods=['GET'])
def list_saves():
    """List all available save games"""
    manager = SaveGameManager()
    saves = manager.list_save_games()
    return jsonify(saves)

@campaigns_bp.route('/save', methods=['POST'])
def create_save():
    """Create a new save game"""
    data = request.get_json() or {}
    description = data.get('description', 'Manual save from mobile')
    save_mode = data.get('mode', 'essential')
    
    manager = SaveGameManager()
    success, message = manager.create_save_game(description, save_mode)
    
    return jsonify({
        "success": success,
        "message": message
    }), 200 if success else 400

@campaigns_bp.route('/restore', methods=['POST'])
def restore_save():
    """Restore a save game"""
    data = request.get_json() or {}
    save_folder = data.get('save_folder')
    
    if not save_folder:
        return jsonify({"success": False, "message": "No save folder specified"}), 400
        
    manager = SaveGameManager()
    success, message = manager.restore_save_game(save_folder)
    
    return jsonify({
        "success": success,
        "message": message
    }), 200 if success else 400

@campaigns_bp.route('/delete-save', methods=['POST'])
def delete_save():
    """Delete a save game"""
    data = request.get_json() or {}
    save_folder = data.get('save_folder')
    
    if not save_folder:
        return jsonify({"success": False, "message": "No save folder specified"}), 400
        
    manager = SaveGameManager()
    success, message = manager.delete_save_game(save_folder)
    
    return jsonify({
        "success": success,
        "message": message
    }), 200 if success else 400
