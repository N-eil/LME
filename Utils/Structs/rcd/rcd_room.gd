extends Resource
class_name RCDRoom

var room_object_count: int
var room_objects: Array
var screens: Array

var screen_count : int
var room_id : int

func _init(id):
	room_id = id

func add_screen(zone_id):#, screen_id):   TODO: add screens in other places
	var s = Screen.make_blank_screen()
	var screen_id = screen_count
	screen_count += 1
	#var neighbouring_screen = screens[screen_id - 1] # TODO: fix other neighbour exits into the new screen too!  This can be hard since they are often in other rooms
	#s.exits[1].copy_exit(neighbouring_screen.exits[1])
	#s.exits[3] = Exit.new(zone_id, room_id, screen_id-1)
	#
	#neighbouring_screen.exits[1] = Exit.new(zone_id, room_id, screen_id)
	screens.append(s)
	
func read(data : StreamPeerBuffer, read_screen_count: int):
	screen_count = read_screen_count
	
	room_object_count = data.get_16()
	for i in range(room_object_count):
		var o = RCDObject.new()
		o.read(data, false)
		room_objects.append(o)
	
	for i in range(screen_count):
		var s = Screen.new()
		s.read(data)
		screens.append(s)
	
func write(buf : StreamPeerBuffer):
	buf.put_16(room_object_count)
	for o in room_objects:
		o.write(buf)
	for s in screens:
		s.write(buf)
