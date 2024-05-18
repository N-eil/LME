#https://discord.com/channels/242731826253266945/334765309904814080/970190778854948914
extends Node
class_name Loader
@onready var object_placeholder_prefab = load("res://ObjectPlaceholder.tscn")

const ROOM_WIDTH = 32
const ROOM_HEIGHT = 24

enum canvas_editing_types {
		NONE = 0,
		LAYERS = 1,
		COLLISION = 2,
		OBJECTS = 3
	}
var current_editing_type = 0

func _on_EditType_tab_changed(tab):
	print(tab)
	current_editing_type = tab + 1

@export var rcd_filename: String
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var loaded_rsd_buffer
var all_fields = []
var all_msd = []
const TILESIZE = 20

#onready var current_directory = OS.get_executable_path().get_base_dir()
const current_directory = "C:/Users/Neil/Documents/godot/Godot_v4.0-stable_win64.exe/la mulana/la mulana editor/LME/"
var msd_directory = current_directory.path_join("MSD")
var graphics_directory = current_directory.path_join("GRAPHICS")

func load_rcd():
	loaded_rsd_buffer = StreamPeerBuffer.new()
	var rsd_file = FileAccess.open(current_directory.path_join("originalscript.rcd"), FileAccess.READ)
	print(current_directory.path_join("originalscript.rcd"))
	var temp_buffer = rsd_file.get_buffer(rsd_file.get_length())
#    print(temp_buffer.size())   
	loaded_rsd_buffer.put_data(temp_buffer)
	loaded_rsd_buffer.big_endian = true
	loaded_rsd_buffer.seek(0)
	loaded_rsd_buffer.get_16()

	rsd_file.close()

func write_rcd(file_to_write, output_buffer):
	file_to_write.store_buffer(output_buffer.data_array)

func load_msd(path, id, sizes_only = false):
	print("Reaing MSD " + path)
	var loaded_buffer = StreamPeerBuffer.new()
	var msd_file = FileAccess.open(path, FileAccess.READ)
	var temp_buffer = msd_file.get_buffer(msd_file.get_length())
	print(temp_buffer.size())   
	loaded_buffer.put_data(temp_buffer)
	loaded_buffer.big_endian = true
	loaded_buffer.seek(0)

	var m = MsdStructs.MSDMap.new()
	if (sizes_only):
		m.read_sizes(loaded_buffer, id)
	else:
		m.read(loaded_buffer, id)

	msd_file.close()
	return m


var current_msd_file : MsdStructs.MSDMap
var current_zone_id
var current_room_id
var current_screen_id

func convert_tile_coord_to_data(layer : MsdStructs.Layer):
	pass
	
func screen_exists(z, r = 0, s = 0):
	if z >= all_fields.size():
		return false
	if r >= all_fields[z].room_count:
		return false
	if s >= all_fields[z].rooms[r].screen_count and all_fields[z].rooms[r].screen_count != 0:
		return false
	return true    
	
func _on_screen_selected(index):
	Messages.emit_signal("new_art_palette", Globals.make_graphics_filename(current_msd_file.graphics_filename))
	#display_screen($RoomCanvas/Visuals, current_zone_id, current_room_id, index)
	$LayerCompositeDisplay.generate_from_msd(current_msd_file, current_room_id, index)
	$CollisionTilemap.from_msd_room(current_msd_file.rooms[current_room_id], index)
	$CollisionTilemap.position = $LayerCompositeDisplay.position
	#$LayerPortionDisplay.display_portion()
	display_objects_in_screen($RoomCanvas/Objects, current_zone_id, current_room_id, index)

func show_object_edit_menu(o):
	$EditType.current_tab = 2
	$EditType/Objects.object = o
	$EditType/Objects.display()
	$EditType.size = Vector2(300,0)
	$EditType/Objects.visible = false
	$EditType/Objects.call_deferred("set_visible", true)
		
func display_objects_in_screen(location, zone_id, room_id, screen_id):
	for c in location.get_children():
		c.queue_free()
 
	if !screen_exists(zone_id, room_id, screen_id) or all_fields[zone_id].rooms[room_id].screen_count == 0:
		return

	var display_screen = all_fields[zone_id].rooms[room_id].screens[screen_id]
 
	for object in display_screen.screen_objects:
		var o = object_placeholder_prefab.instantiate()
		# TODO: Make this work for vertical rooms too
		o.position = Vector2(object.position_x - (screen_id * ROOM_WIDTH), object.position_y - (0 * ROOM_HEIGHT)) * TILESIZE
		o.object = object
		o.editor_ref = self
		location.add_child(o)

	var i = 2
	for object in display_screen.screen_objects_without_position:
		var o = object_placeholder_prefab.instantiate()
		o.position = Vector2(20, ROOM_HEIGHT * 20 + i * 32)
		o.object = object
		o.editor_ref = self
		location.add_child(o)
		i+=1
		
func display_room(zone_id, room_id):
	if (room_id == current_room_id and zone_id == current_zone_id):
		return
	if !screen_exists(zone_id, room_id):
		return
	current_room_id = room_id
	# Uncomment this line to load msd from game directory (loads the ones you previouslly saved instead of fresh ones)
	# CHANGE MSD LOADING HERE
	var msd_directory = "C:/Program Files (x86)/Steam/steamapps/common/La-Mulana/data/mapdata"  
		
	var msd
	if (zone_id == current_zone_id):
		msd = current_msd_file
	else:
		current_zone_id = zone_id
		msd = load_msd(msd_directory.path_join("map" + ("%02d" % zone_id) + ".msd"), zone_id)
		current_msd_file = msd

	$Node2D/RoomJump/HBoxContainer3/ScreenSelector.clear()
	for i in range(current_msd_file.rooms[room_id].screen_count):
		$Node2D/RoomJump/HBoxContainer3/ScreenSelector.add_item(str(i))
	
	current_screen_id = -1
	_on_screen_selected(0)

# Called when the node enters the scene tree for the first time.
func _ready():
	load_rcd()
	
	for i in range(26):
		var f = RcdStructs.Field.new(i)
		var msd = load_msd(msd_directory.path_join("map" + ("%02d" % i) + ".msd"), i, true)
		f.read(loaded_rsd_buffer, msd)
		all_fields.append(f)
		if i >  15:
			print(i)
#        all_msd.append(msd)
#        display_room($RoomCanvas/TileMap, all_msd[0], 0, 0, 0)
	print("READING DONE")    
	
	# Print the info about all objects, mostly for debugging
#	var posfile = FileAccess.open("allpositionobjects.json", FileAccess.WRITE)
#	posfile.store_string(JSON.stringify(Globals.all_position_objects, "  "))
#	var nonposfile = FileAccess.open("allnonpositionobjects.json", FileAccess.WRITE)
#	nonposfile.store_string(JSON.stringify(Globals.all_nonposition_objects, "  "))
	
	
	display_room(1, 1)
#    var temp_storage_file = File.new()
#    temp_storage_file.open("res://tempstore.json", File.WRITE)
#    temp_storage_file.store_string(JSON.stringify(all_fields, "  "))
#    temp_storage_file.close()   

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func _on_Button_pressed():
	# TODO: deep clone instead of reference
#    all_fields[0].rooms[1].screens[1].exits[1].screen_id = 2
#    all_fields[0].rooms[1].screens.append(all_fields[0].rooms[1].screens[1])
#    all_fields[0].rooms[1].screens[2].exits[1].screen_id = 0
#    all_fields[0].rooms[1].screens[2].exits[1].room_id = 2
	$Node2D/RoomJump/Write.text = "Saving..."
	clear_room_visuals(0,5) # Clears out a room for fun visual effects TODDO: Remove

	save_msd_changes()
	save_rcd_changes()
	$Node2D/RoomJump/Write.text = "Write to file"
	
	
func save_msd_changes():
	var output_buffer = StreamPeerBuffer.new()
	output_buffer.big_endian = true
	output_buffer.seek(0)
	current_msd_file.write(output_buffer)

	var game_current_directory = "C:/Program Files (x86)/Steam/steamapps/common/La-Mulana/data/mapdata"
	var written_msd = FileAccess.open(game_current_directory.path_join("map" + ("%02d" % current_zone_id) + ".msd"), FileAccess.WRITE)
	written_msd.store_buffer(output_buffer.data_array)
	written_msd.close()

	print("MSD written!")
	print(current_msd_file.resource_path)
	ResourceSaver.save(current_msd_file, "testres.tres")
	

func save_rcd_changes():
	var game_current_directory = "C:/Program Files (x86)/Steam/steamapps/common/La-Mulana/data/mapdata"
	var write_file = FileAccess.open(game_current_directory.path_join("script.rcd"), FileAccess.WRITE)    
	
	var output_buffer = StreamPeerBuffer.new()
	output_buffer.big_endian = true
	output_buffer.seek(0)
	output_buffer.put_16(0)
	
	for field in all_fields:
		field.write(output_buffer)
	write_rcd(write_file, output_buffer)
	print("RCD WRITTEN")
	write_file.close()


func _on_Jump_pressed():   
	display_room(int($Node2D/RoomJump/HBoxContainer/ZoneEdit.text), int($Node2D/RoomJump/HBoxContainer2/RoomEdit.text))
	
func clear_room_visuals(zone_id, room_id):
	for layer in current_msd_file.rooms[room_id].layers:
		for sub in layer.sublayers:
			for r in sub.tiles:
				for t in r:
					t.coords = 45
					t.type = 1
					
func cell_clicked(tilemap, position):
	print("rcd clicked")
	var new_coords = 34
	var new_object = 0x08
	
	if current_editing_type == canvas_editing_types.LAYERS:
		add_visual_tile(tilemap, position,new_coords)
	elif current_editing_type == canvas_editing_types.OBJECTS:
		add_position_object(position, new_object)
	elif current_editing_type == canvas_editing_types.COLLISION:
		add_collision(position, current_msd_file.rooms[current_room_id])
 
func add_visual_tile(tilemap, position, new_coords, new_type = 1): 
	tilemap.set_cell(position.x, position.y, new_coords)

	var editing_room = current_msd_file.rooms[current_room_id]
	var editing_layer = editing_room.layers[editing_room.prime_layer_index-1] # TODO: Allow editing of different layers!
	var editing_sublayer = editing_layer.sublayers[editing_layer.sublayer_count-1] # TODO: Allow editing of any sublayer!
	var top_left = editing_layer.get_top_left_2d(current_screen_id)
	
	var editing_tile = editing_sublayer.tiles[position.y + top_left.y][position.x + top_left.x]   #current_screen_id) + position.x + (position.y * editing_layer.layer_width)
	
	editing_tile.coords = new_coords
	editing_tile.type = new_type

#    add_collision(position, editing_room)

func add_position_object(position, new_o):
	new_o.position_x = position.x
	new_o.position_y = position.y
	all_fields[current_zone_id].rooms[current_room_id].screens[current_screen_id].add_pos_object(new_o)

func add_collision(position, room, collision_type  = 0x80):  #TODO: More granular collision drawing!

	var top_left = room.get_hitmask_top_left(current_screen_id)
	
	# NOTE TO NEIL: the *2 exits because hitmask cells are half size.  if a hitmask draw mode is made, this might no longer be needed
	room.hit_mask[position.y*2 + top_left.y][position.x*2 + top_left.x] = collision_type
	room.hit_mask[position.y*2 + top_left.y + 1][position.x*2 + top_left.x] = collision_type
	room.hit_mask[position.y*2 + top_left.y][position.x*2 + top_left.x + 1] = collision_type
	room.hit_mask[position.y*2 + top_left.y + 1][position.x*2 + top_left.x + 1] = collision_type  
	

func _on_add_new_room_pressed():
	current_msd_file.rooms[current_room_id].add_screen(current_screen_id)
	all_fields[current_zone_id].rooms[current_room_id].add_screen(current_zone_id)

	$Node2D/RoomJump/HBoxContainer3/ScreenSelector.clear()
	for i in range(current_msd_file.rooms[current_room_id].screen_count):
		$Node2D/RoomJump/HBoxContainer3/ScreenSelector.add_item(str(i))
	
	current_screen_id = -1
	#display_screen($RoomCanvas/Visuals, current_zone_id, current_room_id, 0)
	_on_screen_selected(all_fields[current_zone_id].rooms[current_room_id].screen_count -1)


func _on_LayerTree_button_pressed(item, column, id):
	print(item)
