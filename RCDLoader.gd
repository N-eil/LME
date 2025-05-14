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
var loaded_rcd_buffer

const TILESIZE = 20

#onready var current_directory = OS.get_executable_path().get_base_dir()

#const current_directory = "C:/Users/Neil/Documents/godot/Godot_v4.0-stable_win64.exe/la mulana/la mulana editor/LME/"
#var msd_directory = current_directory.path_join("MSD")
#var graphics_directory = current_directory.path_join("GRAPHICS")
#var rcd_directory = current_directory
#var screenplay_directory = current_directory

var msd_directory 
var graphics_directory 
var rcd_directory 
var screenplay_directory


func load_screenplay(path):
	path = screenplay_directory.path_join("script_code.dat")
	var loaded_buffer = StreamPeerBuffer.new()
	var screenplay_file = FileAccess.open(path, FileAccess.READ)
	var temp_buffer = screenplay_file.get_buffer(screenplay_file.get_length())

	loaded_buffer.put_data(temp_buffer)
	loaded_buffer.big_endian = true
	loaded_buffer.seek(0)
	Globals.all_screenplay = ScreenplayFull.new()
	Globals.all_screenplay.decode_from_stream(loaded_buffer)

func load_rcd():
	loaded_rcd_buffer = StreamPeerBuffer.new()
	var rsd_file = FileAccess.open(rcd_directory.path_join("script.rcd"), FileAccess.READ)
	var temp_buffer = rsd_file.get_buffer(rsd_file.get_length())
#    print(temp_buffer.size())   
	loaded_rcd_buffer.put_data(temp_buffer)
	loaded_rcd_buffer.big_endian = true
	loaded_rcd_buffer.seek(0)
	loaded_rcd_buffer.get_16()

	rsd_file.close()

func write_rcd(file_to_write, output_buffer):
	file_to_write.store_buffer(output_buffer.data_array)

func load_msd(path, id, sizes_only = false):
	print("Reading MSD " + path)
	var loaded_buffer = StreamPeerBuffer.new()
	var msd_file = FileAccess.open(path, FileAccess.READ)
	var temp_buffer = msd_file.get_buffer(msd_file.get_length())
	print(temp_buffer.size())   
	loaded_buffer.put_data(temp_buffer)
	loaded_buffer.big_endian = true
	loaded_buffer.seek(0)

	var m = MSDMap.new()
	if (sizes_only):
		m.read_sizes(loaded_buffer, id)
	else:
		m.read(loaded_buffer, id)

	msd_file.close()
	return m


var current_msd_file : MSDMap
var current_zone_id
var current_room_id
var current_screen_id

func show_fieldmap(field_num):
	var field_info = EditFriendlyField.new(Globals.all_fields[field_num], Globals.all_screenplay.cards[Globals.all_screenplay.map_name_cards[field_num]], Globals.all_screenplay.cards[Globals.all_screenplay.map_display_cards[field_num]])
	$FieldMapView.screen_list_info = field_info
	$FieldMapView.place_screens()


func convert_tile_coord_to_data(layer : Layer):
	pass
	
func screen_exists(z, r = 0, s = 0):
	if z >= Globals.all_fields.size():
		return false
	if r >= Globals.all_fields[z].room_count:
		return false
	if s >= Globals.all_fields[z].rooms[r].screen_count and Globals.all_fields[z].rooms[r].screen_count != 0:
		return false
	return true    
	
func _on_screen_selected(index):

	Messages.emit_signal("new_art_palette", Globals.make_graphics_filename(current_msd_file.graphics_filename))
	$LayerCompositeDisplay.generate_from_msd(current_msd_file, current_room_id, index)
	$CollisionTilemap.from_msd_room(current_msd_file.rooms[current_room_id], index)
	#$LayerPortionDisplay.display_portion()
	display_objects_in_screen($ObjectCanvas, current_zone_id, current_room_id, index)

func show_object_edit_menu(o):
	#$EditType.current_tab = 2
	$ObjectEditor.object = o
	$ObjectEditor.display(o)
	#$EditType.size = Vector2(300,0)
	$ObjectEditor.visible = false
	$ObjectEditor.call_deferred("set_visible", true)
		
func display_objects_in_screen(location, zone_id, room_id, screen_id):
	for c in location.get_children():
		c.queue_free()
 
	if !screen_exists(zone_id, room_id, screen_id) or Globals.all_fields[zone_id].rooms[room_id].screen_count == 0:
		return

	var display_screen = Globals.all_fields[zone_id].rooms[room_id].screens[screen_id]
 
	for object in display_screen.screen_objects:
		var o = object_placeholder_prefab.instantiate()
		# TODO: Make this work for vertical rooms too
		o.position = Vector2(object.position_x - (screen_id * ROOM_WIDTH), object.position_y - (0 * ROOM_HEIGHT)) * TILESIZE
		o.object = object
		o.editor_ref = self
		location.add_child(o)
		print("%s" % object)

	var i = 2
	for object in display_screen.screen_objects_without_position:
		var o = object_placeholder_prefab.instantiate()
		# Just place them all at the bottom of the screen below the art
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

	var msd
	if (zone_id == current_zone_id):
		msd = current_msd_file
	else:
		current_zone_id = zone_id
		msd = load_msd(msd_directory.path_join("map" + ("%02d" % zone_id) + ".msd"), zone_id)
		current_msd_file = msd
		show_fieldmap(zone_id)
		Globals.active_msd = current_msd_file

	$Node2D/RoomJump/HBoxContainer3/ScreenSelector.clear()
	for i in range(current_msd_file.rooms[room_id].screen_count):
		$Node2D/RoomJump/HBoxContainer3/ScreenSelector.add_item(str(i))
	
	current_screen_id = -1
	_on_screen_selected(0)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set up global window references
	Globals.sketchpad_window = $SketchpadWindow
	Globals.collisionpad_window = $CollisionpadWindow

func begin_loading():
	load_rcd() #TODO: read the RCD again
	load_screenplay("ignore this")
	
	
	# Note that it is impossible to parse an entire .rcd file without simultaneously 
	# parsing all the corresponding .msd files, because the .rcd format does not include
	# any explicit markers of how many zones, rooms, or screens there are.
	for i in range(26):
		var f = Field.new(i)
		var msd = load_msd(msd_directory.path_join("map" + ("%02d" % i) + ".msd"), i, true)
		f.read(loaded_rcd_buffer, msd) #Use each loaded msd file to parse its corresponding rcd fiel
		Globals.all_fields.append(f)

	print("READING DONE")

	
	$ScreenplayEditor.setup_dropdown()
	# Print the info about all objects, mostly for debugging
#	var posfile = FileAccess.open("allpositionobjects.json", FileAccess.WRITE)
#	posfile.store_string(JSON.stringify(Globals.all_position_objects, "  "))
#	var nonposfile = FileAccess.open("allnonpositionobjects.json", FileAccess.WRITE)
#	nonposfile.store_string(JSON.stringify(Globals.all_nonposition_objects, "  "))
	
	
	display_room(1, 2)
#    var temp_storage_file = File.new()
#    temp_storage_file.open("res://tempstore.json", File.WRITE)
#    temp_storage_file.store_string(JSON.stringify(all_fields, "  "))
#    temp_storage_file.close()   

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func write_custom_field():
	# Temporary section to write a custom field at field index 1
	var custom_field_id :int = 1
	var room_sizes : Array = [3,3,2,1,2,2,4,4,1,1] #Horizontal length of each room following internal order
	#This writes the RCD portion of the field (exits, objects) with empty rooms of the correct size
	Globals.all_fields[custom_field_id] = Field.make_blank_field()
	for r in room_sizes:
		Globals.all_fields[custom_field_id].add_room(RCDRoom.make_blank_room(r))
	
	#This writes the MSD portion of the field (graphics, collision) with single-layer empty rooms of the correct size 
	current_msd_file = load_msd(msd_directory.path_join("map" + ("%02d" % custom_field_id) + ".msd"), custom_field_id)
	Globals.active_msd = current_msd_file
	current_msd_file.room_count = 0
	current_msd_file.rooms = []
	for r in room_sizes:
		current_msd_file.add_room(MSDRoom.create_large_room(Vector2i(r,1)))
	
	#This writes the screenplay portion of the field (map visuals, room names) with blank entries
	Globals.all_screenplay.clear_field_from_map(custom_field_id)
	
	# For names, first entry is about bgm, 2nd is unused, get these out of the way before the real entries 
	Globals.all_screenplay.cards[Globals.all_screenplay.map_name_cards[custom_field_id]].add_entry_after(ScreenplayEntry.from_string('[0, [["Data", 898, 42, 10]]]'))
	Globals.all_screenplay.cards[Globals.all_screenplay.map_name_cards[custom_field_id]].add_entry_after(ScreenplayEntry.from_string('[5, ["巨人霊廟"]]'))
	# Then, add one name for each screen, keeping in mind a screen contains multiple rooms. Also the first name is the field overall.
	Globals.all_screenplay.cards[Globals.all_screenplay.map_name_cards[custom_field_id]].add_entry_after(ScreenplayEntry.from_string('[5, ["Crystal Temple"]]'))
	for i in room_sizes:
		for j in range(i):
			Globals.all_screenplay.cards[Globals.all_screenplay.map_name_cards[custom_field_id]].add_entry_after(ScreenplayEntry.from_string('[5, ["Placeholder Name"]]'))

	# When writing room locations for the map, there's no filler entries - start right away in MSD/RCD order
	var room_positions : Array = [201, 301, 401, 102, 202, 302, 3, 103, 200, 400, 500, 501, 601, 203, 303, 403, 503, 404, 504, 604, 704, 703, 505]
	for pos in room_positions:
		Globals.all_screenplay.cards[Globals.all_screenplay.map_display_cards[custom_field_id]].add_entry_after(ScreenplayEntry.from_string('[0, [["Data", ' + str(pos) +', 1]]]'))
	
	current_zone_id = custom_field_id

func _on_Button_pressed(game : bool):
	# TODO: deep clone instead of reference
#    all_fields[0].rooms[1].screens[1].exits[1].screen_id = 2
#    all_fields[0].rooms[1].screens.append(all_fields[0].rooms[1].screens[1])
#    all_fields[0].rooms[1].screens[2].exits[1].screen_id = 0
#    all_fields[0].rooms[1].screens[2].exits[1].room_id = 2
	#$Node2D/RoomJump/Write.text = "Saving..."

	if game:
		set_workspace("C:/Program Files (x86)/Steam/steamapps/common/La-Mulana/data")
	else:
		set_workspace("")

	save_msd_changes()
	save_rcd_changes()
	save_screenplay_changes()
	#$Node2D/RoomJump/Write.text = "Write to file"

func save_screenplay_changes():
	var output_buffer = StreamPeerBuffer.new()
	output_buffer.big_endian = true
	output_buffer.seek(0)
	Globals.all_screenplay.write(output_buffer)

	var path = screenplay_directory.path_join("script_code.dat")

	var written_screenplay = FileAccess.open(path, FileAccess.WRITE)
	written_screenplay.store_buffer(output_buffer.data_array)
	written_screenplay.close()

	print("Screenplay written!")

func save_msd_changes():
	var output_buffer = StreamPeerBuffer.new()
	output_buffer.big_endian = true
	output_buffer.seek(0)
	current_msd_file.write(output_buffer)

	var written_msd = FileAccess.open(msd_directory.path_join("map" + ("%02d" % current_zone_id) + ".msd"), FileAccess.WRITE)
	written_msd.store_buffer(output_buffer.data_array)
	written_msd.close()

	print("MSD written!")

func save_rcd_changes():
	var write_file = FileAccess.open(rcd_directory.path_join("script.rcd"), FileAccess.WRITE)    

	var output_buffer = StreamPeerBuffer.new()
	output_buffer.big_endian = true
	output_buffer.seek(0)
	output_buffer.put_16(0)
	
	for field in Globals.all_fields:
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
	Globals.all_fields[current_zone_id].rooms[current_room_id].screens[current_screen_id].add_pos_object(new_o)

func _on_add_new_room_pressed():
	pass
	#current_msd_file.rooms[current_room_id].add_screen(current_screen_id)
	#Globals.all_fields[current_zone_id].rooms[current_room_id].add_screen(current_zone_id)
#
	#$Node2D/RoomJump/HBoxContainer3/ScreenSelector.clear()
	#for i in range(current_msd_file.rooms[current_room_id].screen_count):
		#$Node2D/RoomJump/HBoxContainer3/ScreenSelector.add_item(str(i))
	#
	#current_screen_id = -1
	##display_screen($RoomCanvas/Visuals, current_zone_id, current_room_id, 0)
	#_on_screen_selected(Globals.all_fields[current_zone_id].rooms[current_room_id].screen_count -1)


func _on_LayerTree_button_pressed(item, column, id):
	print(item)


func _on_edit_type_selected(index):
	match index:
		0:
			Globals.current_edit_type = Globals.EditType.NONE
		1:
			Globals.current_edit_type = Globals.EditType.ART
			$SublayerSelector.visible = true
		2:
			Globals.current_edit_type = Globals.EditType.ART_COPY
		3:
			Globals.current_edit_type = Globals.EditType.COLLISION
			$SublayerSelector.visible = false
		4:
			Globals.current_edit_type = Globals.EditType.OBJECT
			$SublayerSelector.visible = false


func set_workspace(path : String):
	if path.is_empty():
		path = "C:/Users/Neil/Documents/godot/Godot_v4.0-stable_win64.exe/la mulana/la mulana editor/LME/LMdata"

	msd_directory = path.path_join("mapdata")
	graphics_directory = path.path_join("graphics/00")
	rcd_directory = path.path_join("mapdata")
	screenplay_directory = path.path_join("/language/en")


func _on_local_pressed():
	set_workspace("C:/Users/Neil/Documents/godot/Godot_v4.0-stable_win64.exe/la mulana/la mulana editor/LME/LMdata")
	$DirectoryButtons.queue_free()
	begin_loading()

func _on_game_pressed():
	set_workspace("C:/Program Files (x86)/Steam/steamapps/common/La-Mulana/data")
	$DirectoryButtons.queue_free()
	begin_loading()
