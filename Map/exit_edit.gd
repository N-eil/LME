extends VBoxContainer

@export var direction : String = "Up" :
	set(s) :
		direction = s
		$Label.text = s

@export var exit_info : Exit : 
	set(e) :
		_field.selected = e.zone_id
		_room.selected = e.room_id
		_screen.selected = e.screen_id
		exit_info = e

@onready var _field = $HBoxContainer/Field
@onready var _room = $HBoxContainer/Room
@onready var _screen = $HBoxContainer/Screen

func dropdown_changed(index, edit_type):
	print("Editing a %s" % edit_type)
	if edit_type == "field":
		exit_info.zone_id = index
	if edit_type == "room":
		exit_info.room_id = index
	if edit_type == "screen":
		exit_info.screen_id = index

func _ready():
	for i in range(30):
		_field.add_item(str(i))
		_room.add_item(str(i))
		_screen.add_item(str(i))

	_field.item_selected.connect(dropdown_changed.bind("field"))
	_room.item_selected.connect(dropdown_changed.bind("room"))
	_screen.item_selected.connect(dropdown_changed.bind("screen"))
