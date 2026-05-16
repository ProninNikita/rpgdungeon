extends SceneTree

const SaveManager = preload("res://scripts/save_manager.gd")

const DEFAULT_SAVE_DIR = "/private/tmp/rpg_save_integrity_check"

var failures: Array = []

func _init() -> void:
	call_deferred("run")

func run() -> void:
	configure_isolated_save_dir()
	cleanup_save_files()
	validate_corrupted_save_handling()
	cleanup_save_files()

	if failures.is_empty():
		print("Save integrity check passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func configure_isolated_save_dir() -> void:
	var save_dir = get_requested_save_dir()
	ProjectSettings.set_setting(SaveManager.SAVE_DIR_SETTING, save_dir)
	if not SaveManager.ensure_save_dir_exists():
		failures.append("Could not create isolated save dir: %s" % save_dir)

func get_requested_save_dir() -> String:
	var user_args = OS.get_cmdline_user_args()
	if not user_args.is_empty() and not str(user_args[0]).strip_edges().is_empty():
		return str(user_args[0]).strip_edges()
	return DEFAULT_SAVE_DIR

func cleanup_save_files() -> void:
	for slot in range(1, SaveManager.SAVE_SLOT_COUNT + 1):
		SaveManager.delete_save_slot(slot)
		remove_if_exists("%s.tmp" % SaveManager.get_save_path(slot))
		remove_if_exists("%s.bak" % SaveManager.get_save_path(slot))

func validate_corrupted_save_handling() -> void:
	if not failures.is_empty():
		return

	var slot = 1
	var save_path = SaveManager.get_save_path(slot)
	var temp_path = "%s.tmp" % save_path
	var backup_path = "%s.bak" % save_path

	assert_true(SaveManager.write_save_slot(slot, {"marker": "initial", "gold": 12}), "initial save write succeeds")
	assert_loaded_marker(slot, "initial", "initial save can be loaded")
	assert_true(not FileAccess.file_exists(temp_path), "initial write leaves no temp file")
	assert_true(not FileAccess.file_exists(backup_path), "initial write leaves no backup file")

	write_text(temp_path, "{\"marker\":\"partial-temp\"")
	assert_loaded_marker(slot, "initial", "partial temp file does not affect active save")

	write_text(backup_path, "{\"marker\":\"stale-backup\"}")
	assert_true(SaveManager.write_save_slot(slot, {"marker": "after_temp", "gold": 18}), "save write replaces stale temp and backup")
	assert_loaded_marker(slot, "after_temp", "save loads after replacing stale temp and backup")
	assert_true(not FileAccess.file_exists(temp_path), "rewrite leaves no temp file")
	assert_true(not FileAccess.file_exists(backup_path), "rewrite removes stale backup file")

	write_text(save_path, "{\"marker\":\"corrupted\"")
	var corrupted = SaveManager.load_save_slot(slot)
	assert_true(corrupted.is_empty(), "corrupted active save loads as empty data")

	assert_true(SaveManager.write_save_slot(slot, {"marker": "recovered", "gold": 24}), "save write recovers corrupted slot")
	assert_loaded_marker(slot, "recovered", "recovered save can be loaded")
	assert_true(not FileAccess.file_exists(temp_path), "recovery leaves no temp file")
	assert_true(not FileAccess.file_exists(backup_path), "recovery removes backup file")

func assert_loaded_marker(slot: int, expected_marker: String, message: String) -> void:
	var save_data = SaveManager.load_save_slot(slot)
	var marker = str(save_data.get("marker", ""))
	assert_true(marker == expected_marker, "%s: expected %s, got %s" % [message, expected_marker, marker])

func write_text(path: String, text: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("Could not write test file: %s" % path)
		return
	file.store_string(text)
	file.flush()

func remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
