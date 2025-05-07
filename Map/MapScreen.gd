extends Area2D
class_name MapScreen

enum MapColours {INVISIBLE, WHITE, GREEN, YELLOW, RED, BLUE, TRANSPARENT}
const map_colour_array : Array[Color] = ["#00000000", Color.WHITE, Color.LIGHT_GREEN, Color.PALE_GOLDENROD, Color.INDIAN_RED, Color.AQUA, "#00000000"]

signal hover (n)
signal click (n)

const ROOM_DIMENSIONS = Vector2i(45, 30)

@export var screen_name : String = "Error missing name"
@export var internal_pos : Vector3i : 
	set (c):
		internal_pos = c
		$Label.text = "%s   %s" % [c.y, c.z]
@export var map_colour : MapColours :
	set (c):
		map_colour = c
		queue_redraw()
@export var first_icon : ScreenplayCard.MapIcons :
	set(c):
		first_icon = c
		$FirstIcon.frame = c
@export var second_icon : ScreenplayCard.MapIcons :
	set(c):
		second_icon = c
		$SecondIcon.frame = c

var internal_position : Vector2i 
var index : int

# Called when the node enters the scene tree for the first time.
func _ready():
	$CollisionShape2D.shape.size = ROOM_DIMENSIONS
	$CollisionShape2D.position = ROOM_DIMENSIONS / 2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _draw():
	draw_rect(Rect2i(Vector2i.ZERO, ROOM_DIMENSIONS), map_colour_array[map_colour])

func _on_mouse_entered():
	self.modulate = Color.LIGHT_SLATE_GRAY
	hover.emit(screen_name)

func _on_mouse_exited():
	self.modulate = Color.WHITE

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			click.emit(index)
