# SPDX-FileCopyrightText: 2024 MoonlightByte
# SPDX-License-Identifier: Fair-Source-1.0
# License: See LICENSE file in the repository root
# This software is subject to the terms of the Fair Source License.

"""
NeverEndingQuest Core Engine - Storage Manager
Copyright (c) 2024 MoonlightByte
Licensed under Fair Source License 1.0

This software is free for non-commercial and educational use.
Commercial competing use is prohibited for 2 years from release.
See LICENSE file for full terms.
"""

import os
import uuid
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple
import jsonschema
from utils.encoding_utils import safe_json_load
from utils.module_path_manager import ModulePathManager
from core.validation.character_validator import AICharacterValidator
from utils.enhanced_logger import debug, info, warning, error, set_script_name

# Set script name for logging
set_script_name(__name__)

from core.database import get_db

class StorageManager:
    """Manages player storage with database-backed persistence"""
    
    def __init__(self, session_id: str = "default"):
        """Initialize storage manager"""
        debug("INITIALIZATION: Starting StorageManager", category="storage_operations")
        self.session_id = session_id
        self.db = get_db()
        self.schema_file = "schemas/storage_action_schema.json"
        # Get current module from party tracker for consistent path resolution
        try:
            party_tracker = self.db.get_party_tracker(self.session_id)
            current_module = party_tracker.get("module", "").replace(" ", "_") if party_tracker else None
            self.path_manager = ModulePathManager(current_module)
            debug(f"INITIALIZATION: Module path manager initialized for module: {current_module}", category="storage_operations")
        except Exception as e:
            warning(f"INITIALIZATION: Could not load party tracker, using default", category="storage_operations")
            self.path_manager = ModulePathManager()  # Fallback to reading from file
        self.character_validator = AICharacterValidator()
        
    def _get_storage_data(self) -> Dict[str, Any]:
        """Retrieve storage data from database"""
        return self.db.get_player_storage(self.session_id)
        
    def _save_storage_data(self, data: Dict[str, Any]) -> bool:
        """Save storage data to database"""
        return self.db.save_player_storage(self.session_id, data)
            
    def _validate_storage_operation(self, operation: Dict[str, Any]) -> bool:
        """Validate storage operation against schema"""
        try:
            if os.path.exists(self.schema_file):
                schema = safe_json_load(self.schema_file)
                jsonschema.validate(operation, schema)
            return True
        except (jsonschema.ValidationError, Exception) as e:
            error(f"VALIDATION: Storage operation validation failed", exception=e, category="storage_operations")
            return False
            
    def _find_item_in_character(self, character_data: Dict[str, Any], item_name: str, quantity: int) -> Tuple[bool, int, Dict[str, Any]]:
        """Find and validate item in character inventory"""
        equipment = character_data.get("equipment", [])
        
        for item in equipment:
            if item.get("item_name") == item_name:
                available_quantity = item.get("quantity", 1)
                if available_quantity >= quantity:
                    return True, available_quantity, item
                else:
                    return False, available_quantity, item
                    
        return False, 0, None
        
    def _remove_item_from_character(self, character_data: Dict[str, Any], item_name: str, quantity: int) -> bool:
        """Remove item from character inventory"""
        equipment = character_data.get("equipment", [])
        
        for i, item in enumerate(equipment):
            if item.get("item_name") == item_name:
                current_quantity = item.get("quantity", 1)
                if current_quantity >= quantity:
                    if current_quantity == quantity:
                        # Remove item completely
                        equipment.pop(i)
                    else:
                        # Reduce quantity
                        item["quantity"] = current_quantity - quantity
                    return True
                    
        return False
        
    def _add_item_to_character(self, character_data: Dict[str, Any], item_data: Dict[str, Any], quantity: int):
        """Add item to character inventory"""
        equipment = character_data.get("equipment", [])
        
        # Check if item already exists in inventory
        for item in equipment:
            if item.get("item_name") == item_data["item_name"]:
                item["quantity"] = item.get("quantity", 1) + quantity
                return
                
        # Add new item to inventory
        new_item = item_data.copy()
        new_item["quantity"] = quantity
        equipment.append(new_item)
        
    def _find_storage_at_location(self, location_id: str) -> List[Dict[str, Any]]:
        """Find all storage containers at a specific location"""
        storage_data = self._get_storage_data()
        return [
            storage for storage in storage_data.get("playerStorage", [])
            if storage.get("locationId") == location_id
        ]
        
    def _get_location_info(self, location_description: str) -> Tuple[str, str, str, str]:
        """Get location information from description"""
        try:
            party_data = self.db.get_party_tracker(self.session_id)
            current_location_id = party_data.get("worldConditions", {}).get("currentLocationId", "UNKNOWN")
            current_location_name = party_data.get("worldConditions", {}).get("currentLocation", "Unknown Location")
            current_area_id = party_data.get("worldConditions", {}).get("currentAreaId", "UNKNOWN")
            current_area_name = party_data.get("worldConditions", {}).get("currentArea", "Unknown Area")
            
            return current_location_id, current_location_name, current_area_id, current_area_name
        except:
            return "UNKNOWN", "Unknown Location", "UNKNOWN", "Unknown Area"
            
    def create_storage(self, operation: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new storage container"""
        debug(f"STATE_CHANGE: Creating storage for character '{operation.get('character')}'", category="storage_operations")
        
        if not self._validate_storage_operation(operation):
            return {"success": False, "error": "Invalid storage operation"}
            
        try:
            # Load current storage data
            storage_data = self._get_storage_data()
            
            # Get location information
            location_id, location_name, area_id, area_name = self._get_location_info(
                operation.get("location_description", "")
            )
            
            # Generate unique storage ID
            storage_id = f"storage_{uuid.uuid4().hex[:8]}"
            
            # Create storage entry
            new_storage = {
                "id": storage_id,
                "deviceType": operation["storage_type"],
                "deviceName": operation.get("storage_name", f"{operation['storage_type'].title()} at {location_name}"),
                "locationId": location_id,
                "locationName": location_name,
                "areaId": area_id,
                "areaName": area_name,
                "contents": [],
                "createdBy": operation["character"],
                "createdDate": datetime.now().isoformat(),
                "accessibility": "party",
                "lastAccessed": datetime.now().isoformat(),
                "accessLog": [
                    {
                        "character": operation["character"],
                        "action": "create",
                        "timestamp": datetime.now().isoformat()
                    }
                ]
            }
            
            # Add to storage data
            storage_data["playerStorage"].append(new_storage)
            storage_data["lastUpdated"] = datetime.now().isoformat()
            
            # Save updated storage data
            if not self._save_storage_data(storage_data):
                raise Exception("Failed to save storage data")
            
            info(f"SUCCESS: Created {operation['storage_type']} '{new_storage['deviceName']}' with ID {storage_id}", category="storage_operations")
            
            return {
                "success": True,
                "storage_id": storage_id,
                "message": f"Created {operation['storage_type']} at {location_name}"
            }
            
        except Exception as e:
            error(f"FAILURE: Failed to create storage - {str(e)}", category="storage_operations")
            return {"success": False, "error": f"Failed to create storage: {str(e)}"}
            
    def store_item(self, operation: Dict[str, Any]) -> Dict[str, Any]:
        """Store an item in a storage container"""
        item_desc = operation.get("item_name", "multiple items") if "item_name" in operation else "multiple items"
        debug(f"STATE_CHANGE: Character '{operation.get('character')}' storing {item_desc}", category="storage_operations")
        
        if not self._validate_storage_operation(operation):
            return {"success": False, "error": "Invalid storage operation"}
            
        try:
            # Load character data
            character_name = operation["character"]
            character_data = self.db.get_character(self.session_id, character_name)
            if not character_data:
                raise Exception(f"Could not load character data for {character_name}")
            
            # Handle both single item and multi-item operations
            items_to_store = []
            if "items" in operation:
                for item_info in operation["items"]:
                    has_item, available_quantity, item_data = self._find_item_in_character(
                        character_data, item_info["item_name"], item_info["quantity"]
                    )
                    if not has_item:
                        raise Exception(f"Character does not have {item_info['item_name']}")
                    if available_quantity < item_info["quantity"]:
                        raise Exception(f"Character only has {available_quantity} {item_info['item_name']}, requested {item_info['quantity']}")
                    items_to_store.append((item_info["item_name"], item_info["quantity"], item_data))
            else:
                has_item, available_quantity, item_data = self._find_item_in_character(
                    character_data, operation["item_name"], operation["quantity"]
                )
                if not has_item:
                    raise Exception(f"Character does not have {operation['item_name']}")
                if available_quantity < operation["quantity"]:
                    raise Exception(f"Character only has {available_quantity} {operation['item_name']}, requested {operation['quantity']}")
                items_to_store.append((operation["item_name"], operation["quantity"], item_data))
                
            # Get or create storage
            storage_id = operation.get("storage_id")
            if not storage_id:
                create_operation = {
                    "action": "create_storage",
                    "character": operation["character"],
                    "storage_type": operation.get("storage_type", "chest"),
                    "storage_name": operation.get("storage_name"),
                    "location_description": operation.get("location_description", "")
                }
                create_result = self.create_storage(create_operation)
                if not create_result["success"]:
                    raise Exception(f"Failed to create storage: {create_result['error']}")
                storage_id = create_result["storage_id"]
                
            storage_data = self._get_storage_data()
            storage_container = next((s for s in storage_data["playerStorage"] if s["id"] == storage_id), None)
                    
            if not storage_container:
                raise Exception(f"Storage container {storage_id} not found")
                
            storage_contents = storage_container["contents"]
            stored_item_names = []
            
            for item_name, quantity, item_data in items_to_store:
                if not self._remove_item_from_character(character_data, item_name, quantity):
                    raise Exception(f"Failed to remove {item_name} from character")
                
                item_found = False
                for stored_item in storage_contents:
                    if stored_item["item_name"] == item_name:
                        stored_item["quantity"] = stored_item.get("quantity", 1) + quantity
                        item_found = True
                        break
                        
                if not item_found:
                    stored_item = item_data.copy()
                    stored_item["quantity"] = quantity
                    stored_item["equipped"] = False
                    storage_contents.append(stored_item)
                
                stored_item_names.append(f"{quantity} {item_name}")
                
            storage_container["lastAccessed"] = datetime.now().isoformat()
            storage_container["accessLog"].append({
                "character": operation["character"],
                "action": "store",
                "timestamp": datetime.now().isoformat()
            })
            
            if not self.db.save_character(self.session_id, character_name, character_data):
                raise Exception("Failed to save character data")
            
            if not self._save_storage_data(storage_data):
                raise Exception("Failed to save storage data")
            
            message = f"Stored items in {storage_container['deviceName']}"
            info(f"SUCCESS: {message}", category="storage_operations")
            
            return {"success": True, "message": message}
            
        except Exception as e:
            error(f"FAILURE: Failed to store item - {str(e)}", category="storage_operations")    
            return {"success": False, "error": f"Failed to store item: {str(e)}"}
            
    def retrieve_item(self, operation: Dict[str, Any]) -> Dict[str, Any]:
        """Retrieve an item from a storage container"""
        item_desc = operation.get("item_name", "multiple items") if "item_name" in operation else "multiple items"
        debug(f"STATE_CHANGE: Character '{operation.get('character')}' retrieving {item_desc}", category="storage_operations")
        
        if not self._validate_storage_operation(operation):
            return {"success": False, "error": "Invalid storage operation"}
            
        try:
            character_name = operation["character"]
            character_data = self.db.get_character(self.session_id, character_name)
            if not character_data:
                raise Exception(f"Could not load character data for {character_name}")
            
            storage_data = self._get_storage_data()
            storage_container = next((s for s in storage_data["playerStorage"] if s["id"] == operation["storage_id"]), None)
                    
            if not storage_container:
                raise Exception(f"Storage container {operation['storage_id']} not found")
                
            items_to_retrieve = []
            if "items" in operation:
                for item_info in operation["items"]:
                    stored_item = next((i for i in storage_container["contents"] if i["item_name"] == item_info["item_name"]), None)
                    if not stored_item:
                        raise Exception(f"{item_info['item_name']} not found in storage")
                        
                    available_quantity = stored_item.get("quantity", 1)
                    if available_quantity < item_info["quantity"]:
                        raise Exception(f"Storage only has {available_quantity} {item_info['item_name']}, requested {item_info['quantity']}")
                        
                    items_to_retrieve.append((item_info["item_name"], item_info["quantity"], stored_item))
            else:
                stored_item = next((i for i in storage_container["contents"] if i["item_name"] == operation["item_name"]), None)
                if not stored_item:
                    raise Exception(f"{operation['item_name']} not found in storage")
                    
                available_quantity = stored_item.get("quantity", 1)
                if available_quantity < operation["quantity"]:
                    raise Exception(f"Storage only has {available_quantity} {operation['item_name']}, requested {operation['quantity']}")
                    
                items_to_retrieve.append((operation["item_name"], operation["quantity"], stored_item))
            
            for item_name, quantity, stored_item in items_to_retrieve:
                available_quantity = stored_item.get("quantity", 1)
                if available_quantity == quantity:
                    storage_container["contents"].remove(stored_item)
                else:
                    stored_item["quantity"] = available_quantity - quantity
                    
                self._add_item_to_character(character_data, stored_item, quantity)
            
            storage_container["lastAccessed"] = datetime.now().isoformat()
            storage_container["accessLog"].append({
                "character": operation["character"],
                "action": "retrieve",
                "timestamp": datetime.now().isoformat()
            })
            
            if not self.db.save_character(self.session_id, character_name, character_data):
                raise Exception("Failed to save character data")
            
            if not self._save_storage_data(storage_data):
                raise Exception("Failed to save storage data")
            
            message = f"Retrieved items from {storage_container['deviceName']}"
            info(f"SUCCESS: {message}", category="storage_operations")
            
            return {"success": True, "message": message}
            
        except Exception as e:
            error(f"FAILURE: Failed to retrieve item - {str(e)}", category="storage_operations")
            return {"success": False, "error": f"Failed to retrieve item: {str(e)}"}
            
    def view_storage(self, location_id: str = None) -> Dict[str, Any]:
        """View storage containers at a location"""
        try:
            storage_data = self._get_storage_data()
            location_storage = self._find_storage_at_location(location_id) if location_id else storage_data.get("playerStorage", [])
                
            storage_info = []
            for storage in location_storage:
                storage_info.append({
                    "id": storage["id"],
                    "name": storage["deviceName"],
                    "type": storage["deviceType"],
                    "location": storage["locationName"],
                    "contents": storage["contents"],
                    "created_by": storage["createdBy"],
                    "last_accessed": storage["lastAccessed"]
                })
                
            return {"success": True, "storage": storage_info, "count": len(storage_info)}
            
        except Exception as e:
            return {"success": False, "error": f"Failed to view storage: {str(e)}"}

def get_storage_manager(session_id: str = "default") -> StorageManager:
    """Get storage manager instance"""
    return StorageManager(session_id)

def execute_storage_operation(operation: Dict[str, Any], session_id: str = "default") -> Dict[str, Any]:
    """Execute a storage operation"""
    manager = get_storage_manager(session_id)
    action = operation.get("action")
    
    if action == "create_storage":
        return manager.create_storage(operation)
    elif action == "store_item":
        return manager.store_item(operation)
    elif action == "retrieve_item":
        return manager.retrieve_item(operation)
    elif action == "view_storage":
        return manager.view_storage(operation.get("location_id"))
    else:
        return {"success": False, "error": f"Unknown storage action: {action}"}
