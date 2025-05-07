extends Resource
class_name LayerArtPortion
# Stores a single layer and all of its sublayers


@export var height : int
@export var width : int
@export var tilesheet_filename : String
@export var layer_count : int = 1
const TILESIZE = 20

@export var stored_layer : Layer

func _init(p_width = 0, p_height = 0, layer_info : Layer = null):
	height = p_height
	width  = p_width
	if layer_info == null or !(layer_info is Layer):
		stored_layer = Layer.new()
		stored_layer.layer_height = height
		stored_layer.layer_width = width
		add_empty_sublayer()
	else:
		stored_layer = layer_info
	#for i in range(height):
		#var t_row : Array = []
		#tile_grid.append(t_row)
		#for j in range(width):
			#t_row.append(MsdStructs.Tile.new)

func add_empty_sublayer():
	var n_slayer = Sublayer.create_empty(width, height)
	stored_layer.add_sublayer(n_slayer)

func copy_portion(top_left : Vector2i = Vector2i.ZERO, size : Vector2i = Vector2i(10,10)):
	var new_portion = LayerArtPortion.new()
	new_portion.tilesheet_filename = tilesheet_filename
	new_portion.width = size.x
	new_portion.height = size.y
	new_portion.layer_count = layer_count
	new_portion.stored_layer = stored_layer.copy_layer_portion(top_left, size)
	return new_portion

#Sets a tile at a coordinate to a specified tile, all info inclded
func set_tile(x,y,t: Tile, sublayer=0):
	if x >= width or y >= height:
		print("Setting an art portion tile outside bounds")
		return
	stored_layer.sublayers[sublayer].tiles[y][x] = t

func clear_tile(x :int, y : int,sublayer : int):
	if x >= width or y >= height:
		printerr("Setting an art portion tile coords outside bounds")
		return

	stored_layer.sublayers[sublayer].tiles[y][x].type = 0

#Sets a tile at a coordinate to use a specific position in the art atlas and specify how it should be flipped
func set_tile_art(x,y,t : int,sublayer=0, flips = [false, false, false]):
	if x >= width or y >= height:
		printerr("Setting an art portion tile coords outside bounds")
		return
	stored_layer.sublayers[sublayer].tiles[y][x].coords = t
	stored_layer.sublayers[sublayer].tiles[y][x].flipped_horizontally = flips[0]
	stored_layer.sublayers[sublayer].tiles[y][x].rotated_90 = flips[1]
	stored_layer.sublayers[sublayer].tiles[y][x].rotated_180 = flips[2]
	if stored_layer.sublayers[sublayer].tiles[y][x].type == 0:
		stored_layer.sublayers[sublayer].tiles[y][x].type = 1
	print("Set tile to ", str(t))

# Gets from an MSD, but all layers must be the same size
static func generate_from_msd(msd : MSDMap, r_index : int = 0, l_index : int = 0):
	var layer : Layer = msd.rooms[r_index].layers[l_index]
	var to_return : LayerArtPortion = LayerArtPortion.new(layer.layer_width, layer.layer_height)
	to_return.width = layer.layer_width
	to_return.height = layer.layer_height
	to_return.stored_layer = layer
	to_return.tilesheet_filename = "res://GRAPHICS/" + msd.graphics_filename
	return to_return
