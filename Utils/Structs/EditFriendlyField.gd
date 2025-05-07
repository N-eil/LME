extends Resource
class_name EditFriendlyField

@export var one_d_screen_array : Array[Screen]
@export var name_card : ScreenplayCard
@export var layout_card : ScreenplayCard
var field : Field

func _init(f : Field, n : ScreenplayCard, l: ScreenplayCard):
	var room_count = 0
	while true:
		var screen_internal_pos : Vector3i = f.linear_order_to_internal_position(room_count)
		if screen_internal_pos.y < 0:
			break
		var s : Screen = f.rooms[screen_internal_pos.y].screens[screen_internal_pos.z]
		s.internal_position = screen_internal_pos
		room_count += 1
		one_d_screen_array.append(s)
	name_card = n
	layout_card = l
	field = f
