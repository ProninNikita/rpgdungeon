extends RefCounted

const MAP_VARIANT = "crypt"

const BATTLE_SHEETS = {
	"hero_base": "res://assets/pixel/battle/hero_base_sheet.png",
	"hero_vampire": "res://assets/pixel/battle/hero_vampire_sheet.png",
	"goblin": "res://assets/pixel/battle/goblin_sheet.png",
	"skeleton": "res://assets/pixel/battle/skeleton_sheet.png",
	"bat": "res://assets/pixel/battle/bat_sheet.png",
	"slime": "res://assets/pixel/battle/slime_sheet.png"
}

static var texture_cache: Dictionary = {}

static func map_texture(asset_name: String, variant: String = MAP_VARIANT) -> Texture2D:
	return load_png_texture("res://assets/pixel/map/%s/%s.png" % [variant, asset_name])

static func battle_sheet(sheet_name: String) -> Texture2D:
	return load_png_texture(str(BATTLE_SHEETS.get(sheet_name, BATTLE_SHEETS["goblin"])))

static func hero_battle_sheet(character_id: String) -> Texture2D:
	if character_id == "vampire":
		return battle_sheet("hero_vampire")
	return battle_sheet("hero_base")

static func enemy_battle_sheet(enemy_type: String) -> Texture2D:
	return battle_sheet(enemy_type)

static func enemy_map_texture(enemy_type: String, variant: String = MAP_VARIANT) -> Texture2D:
	return map_texture("enemy_%s" % enemy_type, variant)

static func load_png_texture(path: String) -> Texture2D:
	if texture_cache.has(path):
		return texture_cache[path]

	if FileAccess.file_exists(path + ".import"):
		var imported_texture = ResourceLoader.load(path)
		if imported_texture is Texture2D:
			texture_cache[path] = imported_texture
			return imported_texture

	var image = Image.new()
	var error = image.load(path)
	if error != OK:
		push_error("Could not load pixel asset: %s" % path)
		return null

	var texture = ImageTexture.create_from_image(image)
	texture_cache[path] = texture
	return texture
