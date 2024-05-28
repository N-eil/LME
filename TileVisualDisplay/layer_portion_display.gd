extends Node2D
class_name LayerPortionDisplay

@export var to_display : LayerArtPortion
@onready var layer_prefab = load("res://MSDLayer.tscn")

var mult_canvas = CanvasItemMaterial.new()
var add_canvas = CanvasItemMaterial.new()
var active_tileset : TileSet
var top_left_offset : Vector2 = Vector2.ZERO

func _ready():
	add_canvas.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mult_canvas.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL

func cell_clicked(l, pos):
	if Globals.current_edit_type == Globals.EditType.ART:
		update_single_cell(l, pos.x, pos.y)

func clear_display():
	for c in get_children():
		c.queue_free()

func update_single_cell(sublayer, x, y):
	var sublayer_index = sublayer.get_index()
	to_display.set_tile_coords(x, y, Globals.active_art_tile_index, sublayer_index, Globals.tile_draw_settings)
	var tile = to_display.stored_layer.sublayers[sublayer_index].tiles[top_left_offset.y + y][top_left_offset.x + x]
	set_single_cell_with_flips(get_child(sublayer_index), Vector2i(x,y), Vector2i(tile.coords%50, floor(tile.coords/50)), Globals.tile_draw_settings)

func set_single_cell_with_flips(tilemap, screen_pos, atlas_pos, flip_flags):
	var alt_tile_id = 0
	if true in flip_flags:
		var t_source =  tilemap.tile_set.get_source(0) as TileSetAtlasSource
		alt_tile_id = t_source.create_alternative_tile(atlas_pos)
	tilemap.set_cell(1, screen_pos, 0, atlas_pos, alt_tile_id)
	var t = tilemap.get_cell_tile_data(1, screen_pos)
	t.flip_h = flip_flags[0]
	t.flip_v = flip_flags[1]
	t.transpose = flip_flags[2]

func display_portion(tilesize = to_display.TILESIZE):
	if not active_tileset: #TODO: call this whenever tileset changes in file
		print("no tileset for layer portion" , self)

	clear_display()
	var layer = to_display.stored_layer

#    if true:
#        var layer = room.layers[room.prime_layer_index - 1]  ONLY SHOW PRIME LAYER
#        $RoomCanvas/TileMap.cell_size = Vector2(TILESIZE/2, TILESIZE/2)
#        var index = 0
#        for h in room.hit_mask:
#            if h:
#                tilemap.set_cell(index % room.hit_mask_width, floor(index / room.hit_mask_width), 0)
#            index += 1    
#        for s in range(layer.sublayers.size() -1, -1,-1):  REVERSE SUBLAYER ORDER
#            var sublayer = layer.sublayers[s]
	var sublayer_z = -1


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
				break
			var j = 0
			while  j < 32:
				if (j >= layer.layer_width):
					break 
				var flip_flags = [false, false, false]                  
				var tile : Sublayer.Tile = sublayer.tiles[top_left_offset.y + i][top_left_offset.x + j]
				if tile.flipped_horizontally:
					flip_flags[0] = !flip_flags[0]
				if tile.rotated_90:
					flip_flags[0] = !flip_flags[0]    
					flip_flags[2] = !flip_flags[2]
				if tile.rotated_180:
					flip_flags[0] = !flip_flags[0]
					flip_flags[1] = !flip_flags[1]                    
				if tile.type != 0:
					# Use TileSetAtlasSource.create_alternative_tile to make alternatives for flipped tiles.
					# Only create flips of the ones that are actually flipped ingame
					# Flip with TileData.flip_h, flip_v, transpose (flags 0-1-2)
					# Use tilemap.get_cell_tile_data to look at specific tiles
#						if (current_msd_file.animated_tiles_map.has(tile.coords)):
#							print("animated tile")
#						else:
					set_single_cell_with_flips(tilemap, Vector2i(j, i), Vector2i(tile.coords%50, floor(tile.coords/50)), flip_flags)
					if (!blend_set):
						blend_set = true
						if tile.type == 2:
							tilemap.material = add_canvas
						if tile.type == 3:
							tilemap.material = mult_canvas             
				j += 1
			i += 1
		sublayer_z = sublayer_z - 1

	#$EditType.size = Vector2(300,600)
