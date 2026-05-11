extends RefCounted

const KEY_OPENED = "opened"
const KEY_GOLD = "gold"
const KEY_ITEM_ID = "item_id"
const KEY_ITEM_ADDED = "item_added"

static func make_reward_result(gold: int = 0, item_id: String = "", item_added: bool = false, opened: bool = false) -> Dictionary:
	return {
		KEY_OPENED: opened,
		KEY_GOLD: gold,
		KEY_ITEM_ID: item_id,
		KEY_ITEM_ADDED: item_added
	}
