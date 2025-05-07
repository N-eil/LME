extends Node2D
class_name TileSetLoader

static var current_tileset_filename : String = "UNLOADED"
static var current_tileset : TileSet

static func load_graphics_to_tileset(path, animated_tiles_map, tilesize = 20):
	var ts = TileSetAtlasSource.new()
	var tex : Texture2D = load(path)
	ts.set_texture(tex)
	ts.set_texture_region_size(Vector2i(tilesize, tilesize))
	for id in range(2500):
		var pos = Vector2(id%50, floor(id/50))
		var size = Vector2(1,1)
		ts.create_tile(pos, size)
#		if animated_tiles_map.has(id):
#			print("framecount")
#			print(animated_tiles_map[id].frame_count)
#			ts.set_tile_animation_columns(pos, 3)
#			ts.set_tile_animation_speed(pos, 2)
#			ts.set_tile_animation_frames_count(pos, 9)
#		ts.tile_set_texture(id, tex)
#		ts.tile_set_region(id, r)
	return ts

static func make_tileset(filename : String, tilesize : int = 20) -> TileSet:
	var screen_tileset = TileSet.new()
	screen_tileset.tile_size = Vector2i(tilesize, tilesize)
	var screen_tile_source = load_graphics_to_tileset(filename, null) #, current_msd_file.animated_tiles_map)
	screen_tileset.add_source(screen_tile_source)
	current_tileset_filename = filename
	current_tileset = screen_tileset
	return screen_tileset

static func get_tilset() -> TileSet:
	return current_tileset
