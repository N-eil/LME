extends TileMap
class_name PaintableTileMap

@export var dimensions : Vector2i = Vector2i(32, 24)
var dragging : bool = false
var clicked_while_dragging : Array[Vector2i]

func click_to_map(click_spot) -> Vector2i:
	var local_position = to_local(click_spot)
	var map_position : Vector2i = local_to_map(local_position)
	return map_position

func _unhandled_input(event : InputEvent):
	if event is InputEventMouseButton:
		dragging = event.pressed
		if event.pressed:
			var map_position = click_to_map(event.position)
			clicked_while_dragging.append(map_position)
			_on_tilemap_click(map_position, event)
			get_viewport().set_input_as_handled()
		else: 
			clicked_while_dragging.clear()
	elif dragging and event is InputEventMouseMotion: #potentially call this less often if performance is a problem
		var map_position = click_to_map(event.position)
		if map_position not in clicked_while_dragging:
			clicked_while_dragging.append(map_position)
			_on_tilemap_click(map_position, event)
			get_viewport().set_input_as_handled()

func _on_tilemap_click(map_position : Vector2i, e : InputEventMouse):
	if (map_position.x < 0 or map_position.y < 0 or map_position.x >= dimensions.x or map_position.y >= dimensions.y):
		return
	do_when_clicked(map_position, e)

func do_when_clicked(tile_position : Vector2i, e : InputEventMouse = null):
	print("Don't call the base paintable tilemap do_when_clicked. You should override this.")

func _ready():
	set_process_unhandled_input(false)
