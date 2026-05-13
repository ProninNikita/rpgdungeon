extends RefCounted

const ItemDatabase = preload("res://scripts/item_database.gd")

static func add_inventory_item(inventory: Array, item_id: String) -> bool:
	if not ItemDatabase.can_add_inventory_item(inventory, item_id):
		return false
	inventory.append(item_id)
	return true

static func equip_inventory_item(inventory: Array, equipment: Dictionary, inventory_index: int) -> bool:
	if inventory_index < 0 or inventory_index >= inventory.size():
		return false

	var item_id = str(inventory[inventory_index])
	var item = ItemDatabase.get_item_definition(item_id)
	if item.is_empty():
		return false

	var slot = str(item.get("slot", ""))
	if not equipment.has(slot):
		return false

	var previous_item_id = str(equipment.get(slot, ""))
	equipment[slot] = item_id
	inventory.remove_at(inventory_index)
	if not previous_item_id.is_empty():
		inventory.append(previous_item_id)
	return true

static func unequip_equipment_slot(inventory: Array, equipment: Dictionary, slot: String) -> bool:
	if not equipment.has(slot):
		return false

	var item_id = str(equipment.get(slot, ""))
	if item_id.is_empty() or not ItemDatabase.can_add_inventory_item(inventory, item_id):
		return false

	equipment[slot] = ""
	inventory.append(item_id)
	return true

static func discard_inventory_item(inventory: Array, inventory_index: int) -> bool:
	if inventory_index < 0 or inventory_index >= inventory.size():
		return false
	inventory.remove_at(inventory_index)
	return true
