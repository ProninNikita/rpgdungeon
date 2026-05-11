extends RefCounted

const SAVE_SLOT_COUNT = 3
const SAVE_FILE_TEMPLATE = "save_slot_%d.json"
const SAVE_DIR_ENV = "RPG_SAVE_DIR"
const SAVE_DIR_SETTING = "rpg/save_dir_override"

static func is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= SAVE_SLOT_COUNT

static func load_save_slot(slot: int) -> Dictionary:
	if not save_slot_exists(slot):
		return {}

	var file = FileAccess.open(get_save_path(slot), FileAccess.READ)
	if file == null:
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	return parsed

static func write_save_slot(slot: int, save_data: Dictionary) -> bool:
	if not is_valid_slot(slot):
		return false
	if not ensure_save_dir_exists():
		return false

	var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	return true

static func delete_save_slot(slot: int) -> bool:
	if not save_slot_exists(slot):
		return false

	return DirAccess.remove_absolute(ProjectSettings.globalize_path(get_save_path(slot))) == OK

static func save_slot_exists(slot: int) -> bool:
	if not is_valid_slot(slot):
		return false
	return FileAccess.file_exists(get_save_path(slot))

static func get_first_empty_save_slot() -> int:
	for slot in range(1, SAVE_SLOT_COUNT + 1):
		if not save_slot_exists(slot):
			return slot
	return 0

static func has_empty_save_slot() -> bool:
	return get_first_empty_save_slot() != 0

static func get_save_path(slot: int) -> String:
	var save_dir = get_save_dir()
	if save_dir == "user://":
		return "user://%s" % get_save_file_name(slot)
	return save_dir.path_join(get_save_file_name(slot))

static func get_save_file_name(slot: int) -> String:
	return SAVE_FILE_TEMPLATE % slot

static func get_save_dir() -> String:
	var override_dir = OS.get_environment(SAVE_DIR_ENV).strip_edges()
	if override_dir.is_empty():
		override_dir = str(ProjectSettings.get_setting(SAVE_DIR_SETTING, "")).strip_edges()
	if not override_dir.is_empty():
		return override_dir
	return "user://"

static func ensure_save_dir_exists() -> bool:
	var save_dir = get_save_dir()
	if save_dir == "user://":
		return true
	if DirAccess.dir_exists_absolute(save_dir):
		return true
	return DirAccess.make_dir_recursive_absolute(save_dir) == OK
