extends Control

signal inventory_toggled(is_open: bool)

const ITEM_ACTION_EQUIP = 0
const ITEM_ACTION_DISCARD = 1
const ITEM_ACTION_UNEQUIP = 2
const EQUIPMENT_SLOT_LABELS = {
	"weapon": "Оружие",
	"armor": "Броня",
	"accessory": "Аксессуар"
}
const ITEM_TYPE_LABELS = {
	"weapon": "Оружие",
	"armor": "Броня",
	"accessory": "Аксессуар"
}
const ITEM_TYPE_TAGS = {
	"weapon": "МЕЧ",
	"armor": "БРН",
	"accessory": "АКС"
}
const ITEM_TYPE_COLORS = {
	"weapon": {
		"bg": Color(0.145, 0.070, 0.055, 0.98),
		"border": Color(0.63, 0.30, 0.22, 1.0),
		"hover": Color(0.205, 0.095, 0.066, 1.0)
	},
	"armor": {
		"bg": Color(0.065, 0.105, 0.128, 0.98),
		"border": Color(0.28, 0.47, 0.56, 1.0),
		"hover": Color(0.085, 0.145, 0.170, 1.0)
	},
	"accessory": {
		"bg": Color(0.122, 0.095, 0.038, 0.98),
		"border": Color(0.66, 0.52, 0.20, 1.0),
		"hover": Color(0.170, 0.130, 0.050, 1.0)
	}
}

@onready var close_button = $Window/Header/CloseButton
@onready var window_panel = $Window
@onready var tabs = $Window/Tabs
@onready var header = $Window/Header
@onready var header_title = $Window/Header/Title
@onready var character_label = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/CharacterLabel
@onready var gold_label = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/GoldLabel
@onready var hp_label = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/HpLabel
@onready var attack_label = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/AttackLabel
@onready var defense_label = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/DefenseLabel
@onready var passives_label = $Window/Tabs/Passives/PassivesContent/EmptyState
@onready var equipment_slots_grid = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/EquipmentSlots
@onready var weapon_slot = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/EquipmentSlots/WeaponSlot
@onready var armor_slot = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/EquipmentSlots/ArmorSlot
@onready var accessory_slot = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/EquipmentSlots/AccessorySlot
@onready var inventory_grid = $Window/Tabs/Equipment/Content/InventoryPanel/InventoryContent/InventoryGrid
@onready var detail_panel = $Window/Tabs/Equipment/Content/DetailPanel
@onready var detail_title = $Window/Tabs/Equipment/Content/DetailPanel/DetailContent/DetailTitle
@onready var detail_type_label = $Window/Tabs/Equipment/Content/DetailPanel/DetailContent/DetailTypeLabel
@onready var detail_slot_label = $Window/Tabs/Equipment/Content/DetailPanel/DetailContent/DetailSlotLabel
@onready var detail_bonus_label = $Window/Tabs/Equipment/Content/DetailPanel/DetailContent/DetailBonusLabel
@onready var detail_equip_button = $Window/Tabs/Equipment/Content/DetailPanel/DetailContent/ActionButtons/EquipButton
@onready var detail_unequip_button = $Window/Tabs/Equipment/Content/DetailPanel/DetailContent/ActionButtons/UnequipButton
@onready var detail_discard_button = $Window/Tabs/Equipment/Content/DetailPanel/DetailContent/ActionButtons/DiscardButton

var inventory_slots: Array = []
var selected_inventory_index: int = -1
var selected_equipment_slot: String = ""
var item_icon_cache: Dictionary = {}
var detail_icon: TextureRect

func _ready() -> void:
	layout_window()
	tabs.set_tab_title(0, "Снаряжение")
	tabs.set_tab_title(1, "Пассивки")
	close_button.pressed.connect(close)
	configure_equipment_cards()
	create_detail_icon()
	collect_inventory_slots()
	connect_inventory_slots()
	connect_equipment_slots()
	connect_detail_actions()
	apply_inventory_style()
	layout_window()
	hide()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and window_panel != null:
		layout_window()

func layout_window() -> void:
	var viewport_size = get_viewport_rect().size
	var edge_margin = 16.0
	var window_size = Vector2(
		min(1040.0, max(320.0, viewport_size.x - edge_margin * 2.0)),
		min(660.0, max(360.0, viewport_size.y - edge_margin * 2.0))
	)
	window_size.x = min(window_size.x, viewport_size.x)
	window_size.y = min(window_size.y, viewport_size.y)
	window_panel.position = Vector2(max(0.0, (viewport_size.x - window_size.x) * 0.5), max(0.0, (viewport_size.y - window_size.y) * 0.5))
	window_panel.size = window_size
	if header != null:
		header.position = Vector2(20.0, 16.0)
		header.size = Vector2(max(0.0, window_size.x - 40.0), 42.0)
	if header_title != null and close_button != null:
		header_title.custom_minimum_size.x = max(0.0, header.size.x - close_button.custom_minimum_size.x - 12.0)
	if tabs != null:
		tabs.position = Vector2(20.0, 72.0)
		tabs.size = Vector2(max(0.0, window_size.x - 40.0), max(0.0, window_size.y - 92.0))
	layout_equipment_tab(tabs.size)

func layout_equipment_tab(tabs_size: Vector2) -> void:
	var equipment_panel = get_node_or_null("Window/Tabs/Equipment/Content/EquipmentPanel") as Panel
	var inventory_panel = get_node_or_null("Window/Tabs/Equipment/Content/InventoryPanel") as Panel
	if equipment_panel == null or inventory_panel == null or detail_panel == null:
		return
	var content_width = max(0.0, tabs_size.x)
	var content_height = max(0.0, tabs_size.y - 32.0)
	var compact = content_width < 760.0
	var separation = 14.0 * 2.0
	var equipment_width = clamp(content_width * 0.27, 142.0 if compact else 220.0, 280.0)
	var detail_width = clamp(content_width * 0.25, 138.0 if compact else 210.0, 270.0)
	var inventory_width = max(132.0, content_width - equipment_width - detail_width - separation)
	equipment_panel.custom_minimum_size = Vector2(equipment_width, 0.0)
	inventory_panel.custom_minimum_size = Vector2(inventory_width, 0.0)
	detail_panel.custom_minimum_size = Vector2(detail_width, 0.0)
	layout_fixed_content("Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent", equipment_width, content_height)
	layout_fixed_content("Window/Tabs/Equipment/Content/InventoryPanel/InventoryContent", inventory_width, content_height)
	layout_fixed_content("Window/Tabs/Equipment/Content/DetailPanel/DetailContent", detail_width, content_height)
	var equipment_inner = max(96.0, equipment_width - 32.0)
	var inventory_inner = max(96.0, inventory_width - 32.0)
	var detail_inner = max(96.0, detail_width - 32.0)
	for label in [$Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/EquipmentTitle, character_label, $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/StatsTitle, gold_label, hp_label, attack_label, defense_label]:
		label.custom_minimum_size.x = equipment_inner
	for slot_button in [weapon_slot, armor_slot, accessory_slot]:
		slot_button.custom_minimum_size = Vector2(equipment_inner, 54.0)
	$Window/Tabs/Equipment/Content/InventoryPanel/InventoryContent/InventoryTitle.custom_minimum_size.x = inventory_inner
	var columns = 4
	if inventory_inner < 330.0:
		columns = 3
	if inventory_inner < 240.0:
		columns = 2
	inventory_grid.columns = columns
	var slot_width = max(54.0, floor((inventory_inner - float(columns - 1) * 9.0) / float(columns)))
	for slot_button in inventory_slots:
		slot_button.custom_minimum_size = Vector2(slot_width, 64.0)
	for label in [detail_title, detail_type_label, detail_slot_label, $Window/Tabs/Equipment/Content/DetailPanel/DetailContent/DetailBonusTitle, detail_bonus_label]:
		label.custom_minimum_size.x = detail_inner
	if detail_icon != null:
		detail_icon.custom_minimum_size = Vector2(detail_inner, 72.0)
	for button in [detail_equip_button, detail_unequip_button, detail_discard_button]:
		button.custom_minimum_size.x = detail_inner

func layout_fixed_content(path: String, panel_width: float, content_height: float) -> void:
	var container = get_node_or_null(path) as Control
	if container == null:
		return
	container.position = Vector2(16.0, 16.0)
	container.size = Vector2(max(0.0, panel_width - 32.0), max(0.0, content_height - 32.0))

func configure_equipment_cards() -> void:
	equipment_slots_grid.columns = 1
	inventory_grid.columns = 3
	inventory_grid.add_theme_constant_override("h_separation", 9)
	inventory_grid.add_theme_constant_override("v_separation", 8)
	for label_name in ["WeaponLabel", "ArmorLabel", "AccessoryLabel"]:
		var label = equipment_slots_grid.get_node_or_null(label_name)
		if label != null:
			label.visible = false
	for slot_button in [weapon_slot, armor_slot, accessory_slot]:
		slot_button.custom_minimum_size = Vector2(248.0, 54.0)

func create_detail_icon() -> void:
	if detail_icon != null:
		return
	detail_icon = TextureRect.new()
	detail_icon.name = "DetailIcon"
	detail_icon.custom_minimum_size = Vector2(238.0, 72.0)
	detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var detail_content = $Window/Tabs/Equipment/Content/DetailPanel/DetailContent
	detail_content.add_child(detail_icon)
	detail_content.move_child(detail_icon, detail_type_label.get_index())

func apply_inventory_style() -> void:
	$Dim.color = Color(0.0, 0.0, 0.0, 0.62)
	window_panel.add_theme_stylebox_override("panel", create_inventory_panel_style(Color(0.040, 0.033, 0.030, 0.98), Color(0.55, 0.40, 0.25, 1.0), 2, 5))
	$Window/Tabs/Equipment/Content/EquipmentPanel.add_theme_stylebox_override("panel", create_inventory_panel_style(Color(0.055, 0.048, 0.043, 0.94), Color(0.36, 0.27, 0.19, 1.0), 1, 4))
	$Window/Tabs/Equipment/Content/InventoryPanel.add_theme_stylebox_override("panel", create_inventory_panel_style(Color(0.055, 0.048, 0.043, 0.94), Color(0.36, 0.27, 0.19, 1.0), 1, 4))
	detail_panel.add_theme_stylebox_override("panel", create_inventory_panel_style(Color(0.052, 0.045, 0.040, 0.96), Color(0.42, 0.31, 0.20, 1.0), 1, 4))
	tabs.add_theme_stylebox_override("panel", create_inventory_panel_style(Color(0.030, 0.027, 0.026, 0.80), Color(0.25, 0.21, 0.17, 1.0), 1, 4))
	tabs.add_theme_stylebox_override("tab_selected", create_inventory_panel_style(Color(0.13, 0.09, 0.055, 0.98), Color(0.64, 0.44, 0.22, 1.0), 1, 3))
	tabs.add_theme_stylebox_override("tab_unselected", create_inventory_panel_style(Color(0.065, 0.055, 0.050, 0.94), Color(0.30, 0.24, 0.19, 1.0), 1, 3))
	tabs.add_theme_color_override("font_selected_color", Color(0.96, 0.78, 0.46, 1.0))
	tabs.add_theme_color_override("font_unselected_color", Color(0.66, 0.58, 0.48, 1.0))
	tabs.add_theme_color_override("font_hovered_color", Color(1.0, 0.88, 0.62, 1.0))
	tabs.add_theme_font_size_override("font_size", 14)
	apply_inventory_label_style(self)
	apply_inventory_button_style(close_button)
	for slot_button in inventory_slots:
		apply_inventory_button_style(slot_button)
	for slot_button in [weapon_slot, armor_slot, accessory_slot]:
		apply_inventory_button_style(slot_button)
	for button in [detail_equip_button, detail_unequip_button, detail_discard_button]:
		apply_inventory_button_style(button)

func apply_inventory_label_style(node: Node) -> void:
	if node is Label:
		var label = node as Label
		label.add_theme_color_override("font_color", Color(0.88, 0.82, 0.72, 1.0))
		label.add_theme_color_override("font_outline_color", Color(0.025, 0.020, 0.018, 1.0))
		label.add_theme_constant_override("outline_size", 1)
	for child in node.get_children():
		apply_inventory_label_style(child)

func apply_inventory_button_style(button: Button) -> void:
	if button == null:
		return
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_theme_color_override("font_color", Color(0.90, 0.82, 0.68, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.90, 0.66, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.70, 0.95, 0.78, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.52, 0.47, 0.40, 1.0))
	button.add_theme_color_override("font_outline_color", Color(0.018, 0.014, 0.012, 1.0))
	button.add_theme_constant_override("outline_size", 1)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_stylebox_override("normal", create_inventory_panel_style(Color(0.085, 0.068, 0.052, 0.96), Color(0.34, 0.25, 0.17, 1.0), 1, 3))
	button.add_theme_stylebox_override("hover", create_inventory_panel_style(Color(0.14, 0.095, 0.060, 0.98), Color(0.68, 0.46, 0.24, 1.0), 1, 3))
	button.add_theme_stylebox_override("pressed", create_inventory_panel_style(Color(0.065, 0.082, 0.060, 1.0), Color(0.52, 0.68, 0.44, 1.0), 1, 3))
	button.add_theme_stylebox_override("disabled", create_inventory_panel_style(Color(0.042, 0.038, 0.036, 0.88), Color(0.18, 0.16, 0.14, 1.0), 1, 3))

func create_inventory_panel_style(background_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style

func get_item_icon_texture(item_id: String, large: bool = false) -> Texture2D:
	if item_id.is_empty():
		return null
	var size = 48 if large else 24
	var cache_key = "%s:%d" % [item_id, size]
	if item_icon_cache.has(cache_key):
		return item_icon_cache[cache_key]
	var texture = create_item_icon_texture(item_id, size)
	item_icon_cache[cache_key] = texture
	return texture

func create_empty_item_icon_texture() -> ImageTexture:
	var cache_key = "empty:48"
	if item_icon_cache.has(cache_key):
		return item_icon_cache[cache_key]
	var image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	draw_item_icon_shadow(image, 24, 32, 14, Color(0.0, 0.0, 0.0, 0.34))
	draw_icon_rect_outline(image, 15, 15, 18, 18, Color(0.070, 0.060, 0.052, 0.72), Color(0.28, 0.22, 0.16, 0.76))
	var texture = ImageTexture.create_from_image(image)
	item_icon_cache[cache_key] = texture
	return texture

func create_item_icon_texture(item_id: String, size: int) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var scale = float(size) / 24.0
	draw_item_icon_shadow(image, int(12 * scale), int(17 * scale), int(7 * scale), Color(0.0, 0.0, 0.0, 0.36))
	var item_type = get_item_type(item_id)
	if item_type == "weapon":
		draw_weapon_icon(image, item_id, scale)
	elif item_type == "armor":
		draw_armor_icon(image, item_id, scale)
	elif item_type == "accessory":
		draw_accessory_icon(image, item_id, scale)
	else:
		draw_icon_rect_outline(image, int(7 * scale), int(6 * scale), int(10 * scale), int(12 * scale), Color(0.34, 0.24, 0.15, 1.0), Color(0.08, 0.06, 0.05, 1.0))
	return ImageTexture.create_from_image(image)

func draw_weapon_icon(image: Image, item_id: String, scale: float) -> void:
	var blade = Color(0.76, 0.82, 0.84, 1.0)
	if item_id == "steel_sword":
		blade = Color(0.88, 0.92, 0.90, 1.0)
	elif item_id == "wooden_sword":
		blade = Color(0.56, 0.32, 0.16, 1.0)
	var outline = Color(0.055, 0.050, 0.050, 1.0)
	for step in range(13):
		var x = int((6 + step) * scale)
		var y = int((17 - step) * scale)
		draw_icon_rect(image, x - int(scale), y - int(scale), max(1, int(3 * scale)), max(1, int(3 * scale)), outline)
		draw_icon_rect(image, x, y - int(scale), max(1, int(2 * scale)), max(1, int(2 * scale)), blade)
	draw_icon_rect_outline(image, int(5 * scale), int(16 * scale), int(9 * scale), max(2, int(2 * scale)), Color(0.58, 0.35, 0.18, 1.0), outline)
	draw_icon_rect_outline(image, int(4 * scale), int(18 * scale), int(4 * scale), int(4 * scale), Color(0.36, 0.20, 0.12, 1.0), outline)

func draw_armor_icon(image: Image, item_id: String, scale: float) -> void:
	var metal = Color(0.40, 0.53, 0.58, 1.0)
	var highlight = Color(0.70, 0.78, 0.78, 1.0)
	if item_id == "leather_chestpiece":
		metal = Color(0.45, 0.24, 0.13, 1.0)
		highlight = Color(0.66, 0.40, 0.23, 1.0)
	elif item_id == "plate_armor":
		metal = Color(0.52, 0.60, 0.62, 1.0)
		highlight = Color(0.86, 0.82, 0.70, 1.0)
	var outline = Color(0.050, 0.045, 0.044, 1.0)
	draw_icon_rect_outline(image, int(7 * scale), int(6 * scale), int(10 * scale), int(13 * scale), metal, outline)
	draw_icon_rect_outline(image, int(5 * scale), int(8 * scale), int(4 * scale), int(7 * scale), metal.darkened(0.18), outline)
	draw_icon_rect_outline(image, int(15 * scale), int(8 * scale), int(4 * scale), int(7 * scale), metal.darkened(0.18), outline)
	draw_icon_rect(image, int(10 * scale), int(8 * scale), max(1, int(2 * scale)), int(10 * scale), highlight)
	draw_icon_rect(image, int(13 * scale), int(8 * scale), max(1, int(scale)), int(10 * scale), metal.darkened(0.25))

func draw_accessory_icon(image: Image, item_id: String, scale: float) -> void:
	var gold = Color(0.86, 0.62, 0.20, 1.0)
	var gem = Color(0.78, 0.18, 0.20, 1.0)
	if item_id == "vitality_ring":
		gem = Color(0.28, 0.76, 0.42, 1.0)
	var outline = Color(0.070, 0.050, 0.025, 1.0)
	if item_id == "ancient_amulet":
		draw_icon_rect_outline(image, int(10 * scale), int(5 * scale), int(4 * scale), int(3 * scale), gold, outline)
		draw_icon_rect_outline(image, int(7 * scale), int(8 * scale), int(10 * scale), int(10 * scale), gold.darkened(0.08), outline)
		draw_icon_rect(image, int(10 * scale), int(11 * scale), int(4 * scale), int(4 * scale), gem)
		draw_icon_rect(image, int(11 * scale), int(12 * scale), int(2 * scale), int(2 * scale), gem.lightened(0.28))
		return
	draw_icon_rect_outline(image, int(7 * scale), int(7 * scale), int(10 * scale), int(10 * scale), gold, outline)
	draw_icon_rect(image, int(10 * scale), int(10 * scale), int(4 * scale), int(4 * scale), Color(0, 0, 0, 0))
	draw_icon_rect_outline(image, int(10 * scale), int(4 * scale), int(4 * scale), int(4 * scale), gem, outline)

func draw_item_icon_shadow(image: Image, center_x: int, center_y: int, radius: int, color: Color) -> void:
	for y in range(center_y - radius, center_y + radius + 1):
		for x in range(center_x - radius, center_x + radius + 1):
			var uv = Vector2(float(x - center_x) / max(1.0, float(radius)), float(y - center_y) / max(1.0, float(radius)))
			var distance = sqrt(uv.x * uv.x + uv.y * uv.y * 2.6)
			var alpha = pow(clamp(1.0 - distance, 0.0, 1.0), 1.4) * color.a
			if alpha > 0.0:
				set_icon_pixel(image, x, y, Color(color.r, color.g, color.b, alpha))

func draw_icon_rect_outline(image: Image, x: int, y: int, width: int, height: int, fill: Color, outline: Color) -> void:
	draw_icon_rect(image, x - 1, y - 1, width + 2, height + 2, outline)
	draw_icon_rect(image, x, y, width, height, fill)

func draw_icon_rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for py in range(y, y + max(1, height)):
		for px in range(x, x + max(1, width)):
			set_icon_pixel(image, px, py, color)

func set_icon_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or x >= image.get_width() or y < 0 or y >= image.get_height():
		return
	image.set_pixel(x, y, color)

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	refresh_character_info()
	show()
	inventory_toggled.emit(true)

func close() -> void:
	hide()
	inventory_toggled.emit(false)

func refresh_character_info() -> void:
	var player_stats = GameState.get_player_battle_stats()
	var base_stats = GameState.get_player_base_stats()
	var equipment_bonuses = GameState.get_equipment_stat_bonuses()
	character_label.text = "Персонаж: %s" % player_stats.get("name", "Герой")
	gold_label.text = "Золото: %d" % GameState.gold
	hp_label.text = get_split_stat_text("HP", int(player_stats.get("hp", 100)), int(player_stats.get("max_hp", 100)), int(base_stats.get("max_hp", 100)), int(equipment_bonuses.get("max_hp", 0)), true)
	attack_label.text = get_split_stat_text("Атака", int(player_stats.get("attack", 10)), 0, int(base_stats.get("attack", 10)), int(equipment_bonuses.get("attack", 0)), false)
	defense_label.text = get_split_stat_text("Защита", int(player_stats.get("defense", 2)), 0, int(base_stats.get("defense", 2)), int(equipment_bonuses.get("defense", 0)), false)
	passives_label.text = get_passives_text(player_stats.get("passives", []))
	validate_selection()
	refresh_equipment_slots()
	refresh_inventory_slots()
	refresh_detail_panel()

func get_split_stat_text(stat_name: String, total_value: int, max_value: int, base_value: int, bonus_value: int, is_hp: bool) -> String:
	var value_text = "%d/%d" % [total_value, max_value] if is_hp else "%d" % total_value
	if bonus_value <= 0:
		return "%s  %s\nБаза %d" % [stat_name, value_text, base_value]
	return "%s  %s\nБаза %d  +%d шмот" % [stat_name, value_text, base_value, bonus_value]

func collect_inventory_slots() -> void:
	inventory_slots.clear()
	for child in inventory_grid.get_children():
		if child is Button:
			inventory_slots.append(child)

func connect_inventory_slots() -> void:
	for index in range(inventory_slots.size()):
		var slot_button = inventory_slots[index]
		slot_button.pressed.connect(_on_inventory_slot_pressed.bind(index))

func connect_equipment_slots() -> void:
	weapon_slot.pressed.connect(_on_equipment_slot_pressed.bind("weapon"))
	armor_slot.pressed.connect(_on_equipment_slot_pressed.bind("armor"))
	accessory_slot.pressed.connect(_on_equipment_slot_pressed.bind("accessory"))

func connect_detail_actions() -> void:
	detail_equip_button.pressed.connect(_on_detail_equip_pressed)
	detail_unequip_button.pressed.connect(_on_detail_unequip_pressed)
	detail_discard_button.pressed.connect(_on_detail_discard_pressed)

func refresh_equipment_slots() -> void:
	refresh_equipment_slot_button(weapon_slot, "weapon")
	refresh_equipment_slot_button(armor_slot, "armor")
	refresh_equipment_slot_button(accessory_slot, "accessory")

func refresh_equipment_slot_button(slot_button: Button, slot: String) -> void:
	var item_id = str(GameState.equipment.get(slot, ""))
	slot_button.text = get_equipment_slot_text(slot)
	slot_button.icon = get_item_icon_texture(item_id, false)
	slot_button.disabled = item_id.is_empty()
	slot_button.tooltip_text = get_item_tooltip(item_id) if not item_id.is_empty() else "%s пусто" % get_equipment_slot_label(slot)
	apply_item_button_style(slot_button, item_id, selected_equipment_slot == slot, true, true)

func get_equipment_slot_text(slot: String) -> String:
	var item_id = str(GameState.equipment.get(slot, ""))
	if item_id.is_empty():
		return "%s\nПусто" % get_equipment_slot_label(slot)
	return "%s\n%s" % [get_equipment_slot_label(slot), compact_item_name(item_id, true)]

func refresh_inventory_slots() -> void:
	for index in range(inventory_slots.size()):
		var slot_button = inventory_slots[index]
		if index >= GameState.inventory.size():
			slot_button.text = ""
			slot_button.icon = null
			slot_button.disabled = true
			slot_button.tooltip_text = ""
			apply_item_button_style(slot_button, "", false, false, false)
			continue

		var item_id = str(GameState.inventory[index])
		slot_button.text = format_inventory_slot_text(item_id)
		slot_button.icon = get_item_icon_texture(item_id, false)
		slot_button.disabled = false
		slot_button.tooltip_text = get_item_tooltip(item_id)
		apply_item_button_style(slot_button, item_id, selected_inventory_index == index, false, false)

func format_inventory_slot_text(item_id: String) -> String:
	return compact_item_name(item_id, false)

func _on_inventory_slot_pressed(index: int) -> void:
	if index < 0 or index >= GameState.inventory.size():
		return

	selected_inventory_index = index
	selected_equipment_slot = ""
	refresh_character_info()

func _on_equipment_slot_pressed(slot: String) -> void:
	var item_id = str(GameState.equipment.get(slot, ""))
	if item_id.is_empty():
		return

	selected_inventory_index = -1
	selected_equipment_slot = slot
	refresh_character_info()

func _on_detail_equip_pressed() -> void:
	perform_selected_item_action(ITEM_ACTION_EQUIP)
	refresh_character_info()

func _on_detail_unequip_pressed() -> void:
	perform_selected_item_action(ITEM_ACTION_UNEQUIP)
	refresh_character_info()

func _on_detail_discard_pressed() -> void:
	perform_selected_item_action(ITEM_ACTION_DISCARD)
	refresh_character_info()

func perform_selected_item_action(action_id: int) -> void:
	if action_id == ITEM_ACTION_EQUIP and selected_inventory_index >= 0:
		var item_id = str(GameState.inventory[selected_inventory_index])
		var slot = get_item_slot(item_id)
		if GameState.equip_inventory_item(selected_inventory_index):
			selected_inventory_index = -1
			selected_equipment_slot = slot
	elif action_id == ITEM_ACTION_DISCARD and selected_inventory_index >= 0:
		if GameState.discard_inventory_item(selected_inventory_index):
			if selected_inventory_index >= GameState.inventory.size():
				selected_inventory_index = GameState.inventory.size() - 1
			selected_equipment_slot = ""
	elif action_id == ITEM_ACTION_UNEQUIP and not selected_equipment_slot.is_empty():
		var slot = selected_equipment_slot
		if GameState.unequip_equipment_slot(selected_equipment_slot):
			selected_equipment_slot = ""
			selected_inventory_index = GameState.inventory.size() - 1
		else:
			selected_equipment_slot = slot

func validate_selection() -> void:
	if selected_inventory_index >= GameState.inventory.size():
		selected_inventory_index = -1
	if selected_inventory_index < -1:
		selected_inventory_index = -1
	if not selected_equipment_slot.is_empty() and str(GameState.equipment.get(selected_equipment_slot, "")).is_empty():
		selected_equipment_slot = ""

func refresh_detail_panel() -> void:
	var item_id = get_selected_item_id()
	if item_id.is_empty():
		if detail_icon != null:
			detail_icon.texture = create_empty_item_icon_texture()
		detail_title.text = "Предмет"
		detail_type_label.text = "Выберите слот"
		detail_slot_label.text = "Клик по предмету покажет детали"
		detail_bonus_label.text = "Бонусы выбранного предмета будут здесь."
		detail_equip_button.disabled = true
		detail_unequip_button.disabled = true
		detail_discard_button.disabled = true
		detail_equip_button.visible = false
		detail_unequip_button.visible = false
		detail_discard_button.visible = false
		detail_panel.add_theme_stylebox_override("panel", create_inventory_panel_style(Color(0.052, 0.045, 0.040, 0.96), Color(0.42, 0.31, 0.20, 1.0), 1, 4))
		return

	var item_type = get_item_type(item_id)
	if detail_icon != null:
		detail_icon.texture = get_item_icon_texture(item_id, true)
	detail_title.text = GameState.get_item_name(item_id)
	detail_type_label.text = "%s  /  %s" % [get_item_type_label(item_type), get_strength_label(item_id)]
	detail_slot_label.text = "Надето" if not selected_equipment_slot.is_empty() else "В рюкзаке"
	detail_bonus_label.text = format_item_detail_bonus_text(item_id)
	detail_equip_button.disabled = selected_inventory_index < 0
	detail_unequip_button.disabled = selected_equipment_slot.is_empty()
	detail_discard_button.disabled = selected_inventory_index < 0
	detail_equip_button.visible = true
	detail_unequip_button.visible = true
	detail_discard_button.visible = true
	var colors = get_item_type_colors(item_type)
	detail_panel.add_theme_stylebox_override("panel", create_inventory_panel_style(colors["bg"].darkened(0.28), colors["border"], 1, 4))

func get_selected_item_id() -> String:
	if selected_inventory_index >= 0 and selected_inventory_index < GameState.inventory.size():
		return str(GameState.inventory[selected_inventory_index])
	if not selected_equipment_slot.is_empty():
		return str(GameState.equipment.get(selected_equipment_slot, ""))
	return ""

func format_item_detail_bonus_text(item_id: String) -> String:
	var bonuses = GameState.get_item_stat_bonuses(item_id)
	if bonuses.is_empty():
		return "Без бонусов"

	var lines = []
	for stat_key in ["attack", "defense", "max_hp"]:
		var value = int(bonuses.get(stat_key, 0))
		if value == 0:
			continue
		lines.append("%s  +%d" % [get_stat_label(stat_key), value])
	return "\n".join(lines)

func get_item_tooltip(item_id: String) -> String:
	if item_id.is_empty():
		return ""
	var bonus_text = GameState.get_item_bonus_text(item_id)
	return GameState.get_item_name(item_id) if bonus_text.is_empty() else "%s\n%s" % [GameState.get_item_name(item_id), bonus_text]

func compact_item_name(item_id: String, is_equipment_card: bool) -> String:
	var item_name = GameState.get_item_name(item_id)
	if is_equipment_card:
		return item_name
	var words = item_name.split(" ", false)
	if words.size() <= 1:
		return item_name
	if item_name.length() <= 12:
		return item_name
	return "%s\n%s" % [str(words[0]), str(words[1])]

func apply_item_button_style(button: Button, item_id: String, is_selected: bool, is_equipped: bool, is_equipment_card: bool) -> void:
	if item_id.is_empty():
		var empty_border = Color(0.22, 0.18, 0.14, 1.0)
		if is_equipment_card:
			empty_border = Color(0.30, 0.24, 0.18, 1.0)
		button.add_theme_stylebox_override("normal", create_inventory_panel_style(Color(0.050, 0.045, 0.040, 0.92), empty_border, 1, 4))
		button.add_theme_stylebox_override("hover", create_inventory_panel_style(Color(0.070, 0.060, 0.050, 0.95), empty_border.lightened(0.2), 1, 4))
		button.add_theme_stylebox_override("pressed", create_inventory_panel_style(Color(0.060, 0.055, 0.050, 0.95), empty_border.lightened(0.1), 1, 4))
		button.add_theme_stylebox_override("disabled", create_inventory_panel_style(Color(0.040, 0.037, 0.034, 0.88), empty_border.darkened(0.25), 1, 4))
		return

	var item_type = get_item_type(item_id)
	var colors = get_item_type_colors(item_type)
	var border_width = 2 if is_selected else 1
	var border_color = Color(1.0, 0.82, 0.42, 1.0) if is_selected else colors["border"]
	if get_item_power_score(item_id) >= 5 and not is_selected:
		border_color = Color(0.86, 0.63, 0.28, 1.0)
	var bg_color = colors["bg"].lightened(0.05) if is_equipped else colors["bg"]
	button.add_theme_stylebox_override("normal", create_inventory_panel_style(bg_color, border_color, border_width, 4))
	button.add_theme_stylebox_override("hover", create_inventory_panel_style(colors["hover"], border_color.lightened(0.18), border_width, 4))
	button.add_theme_stylebox_override("pressed", create_inventory_panel_style(bg_color.darkened(0.16), Color(0.82, 0.92, 0.58, 1.0), 2, 4))
	button.add_theme_stylebox_override("disabled", create_inventory_panel_style(bg_color.darkened(0.25), border_color.darkened(0.30), 1, 4))
	button.add_theme_font_size_override("font_size", 11 if is_equipment_card else 10)

func get_item_power_score(item_id: String) -> int:
	var bonuses = GameState.get_item_stat_bonuses(item_id)
	return int(bonuses.get("attack", 0)) + int(bonuses.get("defense", 0)) + int(bonuses.get("max_hp", 0)) / 5

func get_item_type(item_id: String) -> String:
	var item = GameState.get_item_definition(item_id)
	return str(item.get("type", ""))

func get_item_slot(item_id: String) -> String:
	var item = GameState.get_item_definition(item_id)
	return str(item.get("slot", ""))

func get_item_type_label(item_type: String) -> String:
	return str(ITEM_TYPE_LABELS.get(item_type, "Предмет"))

func get_item_type_tag(item_id: String) -> String:
	return str(ITEM_TYPE_TAGS.get(get_item_type(item_id), "ИТМ"))

func get_item_type_colors(item_type: String) -> Dictionary:
	return ITEM_TYPE_COLORS.get(item_type, {
		"bg": Color(0.085, 0.068, 0.052, 0.96),
		"border": Color(0.34, 0.25, 0.17, 1.0),
		"hover": Color(0.14, 0.095, 0.060, 0.98)
	})

func get_equipment_slot_label(slot: String) -> String:
	return str(EQUIPMENT_SLOT_LABELS.get(slot, slot))

func get_stat_label(stat_key: String) -> String:
	if stat_key == "attack":
		return "Атака"
	if stat_key == "defense":
		return "Защита"
	if stat_key == "max_hp":
		return "HP"
	return stat_key

func get_strength_label(item_id: String) -> String:
	return "Усиленный" if get_item_power_score(item_id) >= 5 else "Обычный"

func get_passives_text(passives: Array) -> String:
	if passives.is_empty():
		return "Пока нет пассивных способностей"

	var descriptions = []
	for passive in passives:
		descriptions.append(format_passive(passive))
	return "\n\n".join(descriptions)

func format_passive(passive: Dictionary) -> String:
	if passive.get("id", "") == "resolve":
		var trigger_percent = int(round(float(passive.get("trigger_hp_percent", 0.0)) * 100.0))
		var heal_percent = int(round(float(passive.get("heal_percent", 0.0)) * 100.0))
		return "%s\nОдин раз за бой лечит на %d%% HP, когда здоровье падает до %d%% или ниже." % [passive.get("name", "Стойкость"), heal_percent, trigger_percent]

	if passive.get("id", "") == "vampirism":
		var heal_percent = int(round(float(passive.get("heal_percent", 0.0)) * 100.0))
		return "%s\nЛечит на %d%% от нанесённого урона после атаки." % [passive.get("name", "Vampirism"), heal_percent]

	return "%s" % passive.get("name", "Неизвестная пассивка")
