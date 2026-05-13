extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")

var failures: Array = []
var game_state = GameStateScript.new()

func _init() -> void:
	validate_inventory_flow()
	if failures.is_empty():
		print("Inventory flow check passed.")
		game_state.free()
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		game_state.free()
		quit(1)

func validate_inventory_flow() -> void:
	game_state.active_save_slot = 0
	game_state.inventory.clear()
	game_state.equipment = game_state.DEFAULT_EQUIPMENT.duplicate()

	assert_true(game_state.add_inventory_item("wooden_sword"), "can add a valid item")
	assert_true(game_state.equip_inventory_item(0), "can equip item from inventory")
	assert_true(str(game_state.equipment.get("weapon", "")) == "wooden_sword", "weapon slot stores equipped item")
	assert_true(game_state.inventory.is_empty(), "equipping removes item from inventory")

	assert_true(game_state.unequip_equipment_slot("weapon"), "can unequip item")
	assert_true(str(game_state.equipment.get("weapon", "")).is_empty(), "weapon slot is empty after unequip")
	assert_true(game_state.inventory.size() == 1 and str(game_state.inventory[0]) == "wooden_sword", "unequipped item returns to inventory")

	assert_true(game_state.discard_inventory_item(0), "can discard inventory item")
	assert_true(game_state.inventory.is_empty(), "discard removes item from inventory")

	for _index in range(game_state.MAX_INVENTORY_SIZE):
		assert_true(game_state.add_inventory_item("wooden_sword"), "can fill inventory")
	assert_true(not game_state.add_inventory_item("wooden_sword"), "full inventory rejects extra item")
	game_state.equipment["armor"] = "leather_chestpiece"
	assert_true(not game_state.unequip_equipment_slot("armor"), "cannot unequip when inventory is full")
	assert_true(str(game_state.equipment.get("armor", "")) == "leather_chestpiece", "failed unequip keeps item equipped")

func assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
