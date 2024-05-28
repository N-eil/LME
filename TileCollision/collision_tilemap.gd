extends PaintableTileMap

@export var top_left_offset : Vector2 = Vector2.ZERO
var associated_room : MSDRoom

func from_msd_room(msd_room : MSDRoom, screen : int = 0):
	clear()
	associated_room = msd_room
	dimensions = Vector2(msd_room.hit_mask_width, msd_room.hit_mask_height)
	top_left_offset = msd_room.get_hitmask_top_left(screen)
	for x in dimensions.y:
		for y in dimensions.x:
			var coord = Vector2(msd_room.hit_mask[x][y] % 16, floor(msd_room.hit_mask[x][y] / 16))			
			set_cell(0,Vector2(y - top_left_offset.x,x-top_left_offset.y),0,coord)
	set_process_unhandled_input(false)

func do_when_clicked(tile_position : Vector2):
	#to_display.set_tile_coords(x, y, Globals.active_art_tile_index, sublayer_index, Globals.tile_draw_settings)
	set_cell(0, tile_position, 0, Vector2i(Globals.active_collision_tile_index%16, floor(Globals.active_collision_tile_index/16)))
	var position_to_save = tile_position + top_left_offset
	associated_room.hit_mask[position_to_save.y][position_to_save.x] = Globals.active_collision_tile_index
	
