extends Resource
class_name Screen

var name_size: int
var screen_object_count: int
var without_position_count: int
var screen_objects_without_position: Array
var screen_objects: Array
var screen_name: Array
var exits: Array
var internal_position : Vector3i


static func make_blank_screen():
	var s = Screen.new()
	s.name_size = 0
	s.screen_name = []
	s.screen_object_count = 0
	s.without_position_count =  0
	s.screen_objects_without_position = []
	s.screen_objects  =  []
	s.exits = []
	for i in range(4):
		s.exits.append(Exit.new())
	return s

func add_pos_object(o):
	screen_object_count += 1
	screen_objects.append(o)

func read(data : StreamPeerBuffer):

	name_size = data.get_8()
	screen_object_count = data.get_16()
	without_position_count = data.get_8()
	
	for i in range(without_position_count):
		var o = RCDObject.new()
		o.read(data, false)
		screen_objects_without_position.append(o)
		
	for i in range(screen_object_count - without_position_count):
		var o = RCDObject.new()
		o.read(data, true)
		screen_objects.append(o)
		
	screen_name = data.get_data(name_size)[1]
	
	for i in range(4):
		var e = Exit.new()
		e.read(data)
		exits.append(e)
	
func write(buf : StreamPeerBuffer):
	buf.put_8(name_size)
	buf.put_16(screen_object_count)
	buf.put_8(without_position_count)
	
	for o in screen_objects_without_position:
		o.write(buf)
	for o in screen_objects:
		o.write(buf)
	buf.put_data(screen_name)
	
	for e in exits:
		e.write(buf)
