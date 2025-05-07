extends Control

var field_info : EditFriendlyField :
	set(s):
		field_info = s
		$"VBoxContainer/Field Name".text = field_info.name_card.entries[2].info[0]
		$"VBoxContainer/Screen Name".text = field_info.name_card.entries[index_in_field + 3].info[0]
		make_exit_nodes()
		make_icons()

var index_in_field : int

@onready var exit_nodes = [$VBoxContainer/HBoxContainer/ExitEdit, $VBoxContainer/HBoxContainer2/ExitEdit2, $VBoxContainer/HBoxContainer3/ExitEdit, $VBoxContainer/HBoxContainer2/ExitEdit]

var icon_and_colour_indexes : Vector3i = Vector3i.ZERO

func setup_screen_info(f : EditFriendlyField, i : int):
	index_in_field = i
	field_info = f
	
func make_exit_nodes():
	if not field_info.one_d_screen_array:
		printerr("Screen info is missing for a screen edit node!")
		return
	var directions = ["Up", "Right", "Down", "Left"]
	for i in range(4):
		exit_nodes[i].direction = directions[i]
		exit_nodes[i].exit_info = field_info.one_d_screen_array[index_in_field].exits[i]

func make_icons():
	icon_and_colour_indexes = ScreenplayCard.icon_num_to_vec(field_info.layout_card.entries[index_in_field].info[0][2])
	$VBoxContainer/HBoxContainer2/TextureRect/Icon1.frame = icon_and_colour_indexes.x
	$VBoxContainer/HBoxContainer2/TextureRect/Icon2.frame = icon_and_colour_indexes.y

func _on_icon_input_event(viewport, event, shape_idx, first_icon):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var editing_icon : Sprite2D
			if first_icon:
				icon_and_colour_indexes.x = (icon_and_colour_indexes.x + 1) % ScreenplayCard.MapIcons.size()
				$VBoxContainer/HBoxContainer2/TextureRect/Icon1.frame = icon_and_colour_indexes.x
			else:
				icon_and_colour_indexes.y = (icon_and_colour_indexes.y + 1) % ScreenplayCard.MapIcons.size()
				$VBoxContainer/HBoxContainer2/TextureRect/Icon2.frame = icon_and_colour_indexes.y
			field_info.layout_card.entries[index_in_field].info[0][2] = ScreenplayCard.icon_vec_to_num(icon_and_colour_indexes)


func _on_field_name_text_submitted(new_text):
	field_info.name_card.entries[2].info[0] = new_text


func _on_screen_name_text_submitted(new_text):
	field_info.name_card.entries[index_in_field + 3].info[0] = new_text
