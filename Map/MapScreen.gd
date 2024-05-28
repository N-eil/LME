extends Area2D
class_name MapScreen

enum MapColours {INVISIBLE, WHITE, GREEN, YELLOW, RED, BLUE, TRANSPARENT}
const map_colour_array : Array[Color] = ["#00000000", Color.WHITE, Color.LIGHT_GREEN, Color.PALE_GOLDENROD, Color.INDIAN_RED, Color.AQUA, "#00000000"]

enum MapIcons {BLANK, BACKSIDE, GRAIL, CROSS, FAIRY, BROWNDOOR, BLUEDOOR, PHILOSOPHER, UP, DOWN, LEFT, RIGHT, BONE}

signal hover (n)

const ROOM_DIMENSIONS = Vector2i(45, 30)

@export var screen_name : String = "Error missing name"
@export var map_position : Vector2
@export var map_colour : MapColours :
	set (c):
		map_colour = c
		queue_redraw()
@export var first_icon : MapIcons
@export var second_icon : MapIcons

var internal_location : Array 


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
