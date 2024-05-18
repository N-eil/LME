extends TileMap
class_name PaintableTileMap

@export var dimensions : Vector2 = Vector2(32, 24)
var dragging : bool = false

func _unhandled_input(event):
	if event is InputEventMouseButton:
		dragging = event.pressed
		if event.pressed:
			_on_tilemap_click(event)
			get_viewport().set_input_as_handled()
	if dragging and event is InputEventMouseMotion: #TODO: potentially call this less often if performance is a problem
		_on_tilemap_click(event)
		get_viewport().set_input_as_handled()

func _on_tilemap_click(event):
	var local_position = to_local(event.position)
	var map_position : Vector2 = local_to_map(local_position)
	if (map_position.x < 0 or map_position.y < 0 or map_position.x >= dimensions.x or map_position.y >= dimensions.y):
		return
	do_when_clicked(map_position)

func do_when_clicked(position : Vector2):
	print("Don't call the base paintable tilemap do_when_clicked. You should override this.")

func _ready():
	set_process_unhandled_input(false)
