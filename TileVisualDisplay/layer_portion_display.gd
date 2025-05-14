extends Node2D
class_name LayerPortionDisplay

@export var to_display : LayerArtPortion
@onready var layer_prefab = load("res://MSDLayer.tscn")


var active_tileset : TileSet
var top_left_offset : Vector2i = Vector2i.ZERO

func cell_clicked(l, pos : Vector2i, e : InputEventMouse):
	if Globals.current_edit_type != Globals.EditType.ART:
		return

	pos += top_left_offset

	# When holding ctrl, first click is top left, 2nd click is bottom right of copy box
	if e.ctrl_pressed:
		if Globals.copy_top_left == Vector2i(-1,-1):
			Globals.copy_top_left = pos
		else:
			var w : Node = Globals.sketchpad_window
			w.set_sketchpad_art_with_backup(to_display.copy_portion(Globals.copy_top_left, pos - Globals.copy_top_left + Vector2i(1,1)))
			Globals.copy_top_left = Vector2i(-1,-1)
		return

	# When holding alt, paste the sketchpad's top left at the clicked cell
	if e.alt_pressed:
		var w : Node = Globals.sketchpad_window
		var source_layer : Layer = w.convert_to_layer_data().stored_layer
		to_display.stored_layer.replace_layer_portion(pos, source_layer)
		update_all_cells_onscreen()
		return


	# Right click is the erase button
	if e.button_mask == MOUSE_BUTTON_RIGHT:
		to_display.clear_tile(pos.x, pos.y, l.get_index())
		l.erase_cell(1, pos)
		return

	# Basic left click without modifiers just draws normally
	update_single_cell_in_data(l, pos.x, pos.y)

#	elif Globals.current_edit_type == Globals.EditType.ART_COPY: #TODO: Make a script on the sketchpad window instead of directly calling child scripts 
#		var w : Node = Globals.sketchpad_window
#		w.set_sketchpad_art_with_backup(to_display.copy_portion(pos))
		#w.get_child(0).active_tileset = active_tileset
		#w.get_child(0).display_portion()

func clear_display():
	for c in get_children():
		c.free()

# Updates a single cell in the underlying Sublayer data structure, then updates on screen
func update_single_cell_in_data(sublayer, x, y):
	var sublayer_index = sublayer.get_index()
	to_display.set_tile_art(x, y, Globals.active_art_tile_index, sublayer_index, Globals.tile_draw_settings)
	update_single_cell_onscreen(sublayer_index, x, y)

# Updates a single cell onscreen without changing the underlying data. Use when changing the sublayer or to fix desyncs.
func update_single_cell_onscreen(sublayer_index:int, x:int, y :int):
	var tile : Tile = to_display.stored_layer.sublayers[sublayer_index].tiles[y][x]
	if tile.type != 0:
		set_single_cell_with_flips(get_child(sublayer_index), Vector2i(x,y) - top_left_offset, Vector2i(tile.coords%50, floor(tile.coords/50)), tile.make_art_flip_flags())
		set_tilemap_blending(get_child(sublayer_index), tile)

func update_all_cells_onscreen():
	for s in range(to_display.stored_layer.sublayer_count):
		for x in range(32):
			for y in range(24):
				update_single_cell_onscreen(s, x, y)

func set_single_cell_with_flips(tilemap : TileMap, screen_pos, atlas_pos, flip_flags):
	var alt_tile_id = 0
	if true in flip_flags:
		var t_source =  tilemap.tile_set.get_source(0) as TileSetAtlasSource
		alt_tile_id = t_source.create_alternative_tile(atlas_pos)
	tilemap.set_cell(1, screen_pos, 0, atlas_pos, alt_tile_id)
	var t = tilemap.get_cell_tile_data(1, screen_pos)
	t.flip_h = flip_flags[0]
	t.flip_v = flip_flags[1]
	t.transpose = flip_flags[2]

#In theory, each cell can have its own blending.
#In practice, all tiles on a sublayer share a blend mode so it is safe to set the entire thing off one tile 
func set_tilemap_blending(tilemap :TileMap, tile : Tile):
	if tile.type == 2:
		tilemap.material = Globals.add_canvas
	if tile.type == 3:
		tilemap.material = Globals.mult_canvas 

func display_portion(tilesize = to_display.TILESIZE):
	if not active_tileset: #TODO: call this whenever tileset changes in file
		print("no tileset for layer portion" , self)

	clear_display()
	var layer = to_display.stored_layer

#    if true:
#        var layer = room.layers[room.prime_layer_index - 1]  ONLY SHOW PRIME LAYER
#        $RoomCanvas/TileMap.cell_size = Vector2(TILESIZE/2, TILESIZE/2)
#        var index = 0
#        for h in room.hitmask:
#            if h:
#                tilemap.set_cell(index % room.hitmask_width, floor(index / room.hitmask_width), 0)
#            index += 1    
#        for s in range(layer.sublayers.size() -1, -1,-1):  REVERSE SUBLAYER ORDER
#            var sublayer = layer.sublayers[s]
	var sublayer_z = -1

	#print("Sublayer count " + str(layer.sublayer_count))
	#print("Sublayer actual count " + str(len(layer.sublayers)))
	#print("Children count " + str(get_child_count()))
	for sublayer in layer.sublayers:
		var tilemap : TileMap = layer_prefab.instantiate()
		tilemap.cell_quadrant_size = to_display.TILESIZE
		tilemap.tile_set = active_tileset
		tilemap.add_layer(-1)
		add_child(tilemap)
		tilemap.z_index = sublayer_z
		

		sublayer_z -= 1
		#if (layer.horizontal_screen_count < 1):
			#tilemap.width = layer.layer_width
			#tilemap.height = layer.layer_height
		
		var blend_set = false
		var i = 0
		while i < 24:
			if (i >= layer.layer_height):
				tilemap.dimensions.y = layer.layer_height
				break
			var j = 0
			while  j < 32:
				if (j >= layer.layer_width):
					tilemap.dimensions.x = layer.layer_width
					break
				var tile : Tile = sublayer.tiles[top_left_offset.y + i][top_left_offset.x + j]                  
				if tile.type != 0:
					# Use TileSetAtlasSource.create_alternative_tile to make alternatives for flipped tiles.
					# Only create flips of the ones that are actually flipped ingame
					# Flip with TileData.flip_h, flip_v, transpose (flags 0-1-2)
					# Use tilemap.get_cell_tile_data to look at specific tiles
#						if (current_msd_file.animated_tiles_map.has(tile.coords)):
#							print("animated tile")
#						else:
					set_single_cell_with_flips(tilemap, Vector2i(j, i), Vector2i(tile.coords%50, floor(tile.coords/50)), tile.make_art_flip_flags())
					if (!blend_set):
						blend_set = true
						set_tilemap_blending(tilemap, tile)            
				j += 1
			i += 1
		sublayer_z = sublayer_z - 1

	#$EditType.size = Vector2(300,600)
