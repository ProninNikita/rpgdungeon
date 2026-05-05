extends Node2D

const ROOM_WIDTH = 16
const ROOM_HEIGHT = 16
const TILE_SIZE = 32

func _ready():
	pass

func _draw():
	# Вертикальные линии
	for x in range(ROOM_WIDTH + 1):
		var from = Vector2(x * TILE_SIZE, 0)
		var to = Vector2(x * TILE_SIZE, ROOM_HEIGHT * TILE_SIZE)
		draw_line(from, to, Color(0.3, 0.3, 0.35, 0.5), 1.0)
	
	# Горизонтальные линии
	for y in range(ROOM_HEIGHT + 1):
		var from = Vector2(0, y * TILE_SIZE)
		var to = Vector2(ROOM_WIDTH * TILE_SIZE, y * TILE_SIZE)
		draw_line(from, to, Color(0.3, 0.3, 0.35, 0.5), 1.0)

func get_room_bounds() -> Rect2:
	return Rect2(0, 0, ROOM_WIDTH * TILE_SIZE, ROOM_HEIGHT * TILE_SIZE)
