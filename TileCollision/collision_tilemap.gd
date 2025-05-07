extends PaintableTileMap
class_name CollisionTileMap

@export var top_left_offset : Vector2i = Vector2i.ZERO
var associated_room : MSDRoom
var hitmask_data : Array[Array] = []


func _ready():
	Messages.connect("edit_type_changed", edit_type_changed)
	position = Vector2i.ZERO
	set_process_unhandled_input(false)

func from_msd_room(msd_room : MSDRoom, screen : int = 0):
	hitmask_data = msd_room.hitmask
	dimensions = Vector2i(msd_room.hitmask_width, msd_room.hitmask_height)
	top_left_offset = msd_room.get_hitmask_top_left(screen)
	setup_cells()

func from_hitmask(hitmask : Array[Array]):
	hitmask_data = hitmask
	dimensions = Vector2i(len(hitmask[0]), len(hitmask))
	setup_cells()

func blank_from_dimensions(new_dimensions : Vector2i):
	dimensions = new_dimensions
	hitmask_data = []
	for y in dimensions.y:
		var temp : Array = []
		for x in dimensions.x:
			temp.append(0)
		hitmask_data.append(temp)
	setup_cells()

func setup_cells():
	clear()
	$TileGridlines.width = dimensions.x
	$TileGridlines.height = dimensions.y
	for x in dimensions.y:
		for y in dimensions.x:
			var coord = Vector2(hitmask_data[x][y] % 16, floor(hitmask_data[x][y] / 16))
			set_cell(0,Vector2(y - top_left_offset.x,x-top_left_offset.y),0,coord)

func do_when_clicked(tile_position : Vector2i, e : InputEventMouse = null):
	var position_to_save = tile_position + top_left_offset
	# Right click will clear the collision on a tile
	var tile_palette_index : int = 0 if e.button_mask == MOUSE_BUTTON_RIGHT else Globals.active_collision_tile_index

	set_cell(0, tile_position, 0, Vector2i(tile_palette_index%16, floor(tile_palette_index/16)))
	hitmask_data[position_to_save.y][position_to_save.x] = tile_palette_index

func edit_type_changed(e):
	set_process_unhandled_input(e == Globals.EditType.COLLISION)
