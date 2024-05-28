extends Node
class_name RcdStructs


class Field:
	var name_size: int
	var objects_count: int
	var name: Array  # Array of bytes. Need to decode as UTF16 for text. Does nothing, do not name a zone by writing to this
	var objects: Array
	var rooms: Array

	var room_count : int
	var zone_id : int

	func _init(id):
		zone_id = id

	func add_screen(room_id): #TODO: Add screens to other places than just directly right
		room_count += 1
		rooms[room_id].add_screen(zone_id)

	func read(data : StreamPeerBuffer, msd : MSDMap):
		room_count = msd.room_count
		
		name_size = data.get_8()
		objects_count = data.get_16()
		name = data.get_data(name_size)[1]
		
		for i in range(objects_count):
			var o = ObjectWithoutPosition.new()
			o.read(data)
			objects.append(o)
			
		for i in range(room_count):
			var r = EditorRoom.new(i)
			var temp_screencount = msd.rooms[i].screen_count
			r.read(data, temp_screencount)
			rooms.append(r)
		
#        print("Read a zone with room count of %d and actual size %d" % [room_count, rooms.size()])
		
	func write(buf : StreamPeerBuffer):
		buf.put_8(name_size)
		buf.put_16(objects_count)
		buf.put_data(name)
		
		for o in objects:
			o.write(buf)
		for r in rooms:
			r.write(buf)

class EditorRoom:
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
		var neighbouring_screen = screens[screen_id - 1] # TODO: fix other neighbour exits into the new screen too!  This can be hard since they are often in other rooms
		s.exits[1].copy_exit(neighbouring_screen.exits[1])
		s.exits[3] = Exit.new(zone_id, room_id, screen_id-1)
		
		neighbouring_screen.exits[1] = Exit.new(zone_id, room_id, screen_id)
		screens.append(s)
		
	func read(data : StreamPeerBuffer, read_screen_count: int):
		screen_count = read_screen_count
		
		room_object_count = data.get_16()
		for i in range(room_object_count):
			var o = ObjectWithoutPosition.new()
			o.read(data)
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
 
class Screen:
	var name_size: int
	var screen_object_count: int
	var without_position_count: int
	var screen_objects_without_position: Array
	var screen_objects: Array
	var screen_name: Array
	var exits: Array

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
			var o = ObjectWithoutPosition.new()
			o.read(data)
			screen_objects_without_position.append(o)
			
		for i in range(screen_object_count - without_position_count):
			var o = ObjectWithPosition.new()
			o.read(data)
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

class Exit:
	var zone_id: int
	var room_id: int
	var screen_id: int
   
	func _init(z = -1,r = -1,s = -1):
		zone_id = z
		room_id = r
		screen_id = s
	
	func copy_exit(source_exit):
		zone_id = source_exit.zone_id
		room_id = source_exit.room_id
		screen_id = source_exit.screen_id
	
	func read(data : StreamPeerBuffer):
		zone_id = data.get_8()
		room_id = data.get_8()
		screen_id = data.get_8()
		
	func write(buf : StreamPeerBuffer):
		buf.put_8(zone_id)
		buf.put_8(room_id)
		buf.put_8(screen_id)

class ObjectWithoutPosition:
	var object_id : int
	var number_of_test_flags : int
	var number_of_write_flags : int
	var number_of_parameters : int
	var test_byte_operations : Array
	var write_byte_operations : Array
	var parameters : Array
	
	func read(data : StreamPeerBuffer):
		object_id  = data.get_16()
		var number_of_flags = data.get_u8()
		number_of_test_flags = number_of_flags >> 4
		number_of_write_flags  = number_of_flags & 15
		number_of_parameters = data.get_8()

		# Code that surveys the parameters and flags of all objects in the game. Useful to build a list of what is valid and what is not	
#		var hex_id = ("0x%02X" % object_id)
#		if hex_id in Globals.all_nonposition_objects:
#			if number_of_parameters not in Globals.all_nonposition_objects[hex_id]["parameter_count"]:
#				Globals.all_nonposition_objects[hex_id]["parameter_count"].append(number_of_parameters)
#			if number_of_test_flags not in Globals.all_nonposition_objects[hex_id]["testflag_count"]:
#				Globals.all_nonposition_objects[hex_id]["testflag_count"].append(number_of_test_flags)
#			if number_of_write_flags not in Globals.all_nonposition_objects[hex_id]["writeflag_count"]:
#				Globals.all_nonposition_objects[hex_id]["writeflag_count"].append(number_of_write_flags)
#		else:
#			Globals.all_nonposition_objects[hex_id] = {"parameter_count": [number_of_parameters], "testflag_count": [number_of_test_flags], "writeflag_count": [number_of_write_flags]}
		
		
		for i in range(number_of_test_flags):
			var o = TestFlag.new()
			o.read(data)
			test_byte_operations.append(o)
		
		for i in range(number_of_write_flags):
			var o = WriteFlag.new()
			o.read(data)
			write_byte_operations.append(o)
			
		for i in range(number_of_parameters):
			var o = data.get_16()
			parameters.append(o)
			
	func write(buf : StreamPeerBuffer):
		buf.put_16(object_id)
		var number_of_flags = ((number_of_test_flags << 4) + number_of_write_flags)
		buf.put_8(number_of_flags)
		buf.put_8(number_of_parameters)
		
		for t in test_byte_operations:
			t.write(buf)
		for w in write_byte_operations:
			w.write(buf)
		for p in parameters:
			buf.put_16(p)

class ObjectWithPosition:
	var object_id : int
	var number_of_test_flags : int
	var number_of_write_flags : int
	var number_of_parameters : int
	var position_x : int
	var position_y : int
	var test_byte_operations : Array
	var write_byte_operations : Array
	var parameters : Array  
	
	func read(data : StreamPeerBuffer):
		object_id  = data.get_16()
		var number_of_flags = data.get_u8()
		number_of_test_flags = number_of_flags >> 4
		number_of_write_flags  = number_of_flags & 15
		number_of_parameters = data.get_8()
		position_x  = data.get_16()
		position_y  = data.get_16()
		
		# Code that surveys the parameters and flags of all objects in the game. Useful to build a list of what is valid and what is not	
#		var hex_id = ("0x%02X" % object_id)
#		if hex_id in Globals.all_position_objects:
#			if number_of_parameters not in Globals.all_position_objects[hex_id]["parameter_count"]:
#				Globals.all_position_objects[hex_id]["parameter_count"].append(number_of_parameters)
#			if number_of_test_flags not in Globals.all_position_objects[hex_id]["testflag_count"]:
#				Globals.all_position_objects[hex_id]["testflag_count"].append(number_of_test_flags)
#			if number_of_write_flags not in Globals.all_position_objects[hex_id]["writeflag_count"]:
#				Globals.all_position_objects[hex_id]["writeflag_count"].append(number_of_write_flags)
#		else:
#			Globals.all_position_objects[hex_id] = {"parameter_count": [number_of_parameters], "testflag_count": [number_of_test_flags], "writeflag_count": [number_of_write_flags]}
	
		
		for i in range(number_of_test_flags):
			var o = TestFlag.new()
			o.read(data)
			test_byte_operations.append(o)
		
		for i in range(number_of_write_flags):
			var o = WriteFlag.new()
			o.read(data)
			write_byte_operations.append(o)
			
		for i in range(number_of_parameters):
			var o = data.get_16()
			parameters.append(o)
		
	func write(buf : StreamPeerBuffer):
		buf.put_16(object_id)
		var number_of_flags = ((number_of_test_flags << 4) + number_of_write_flags)
		buf.put_8(number_of_flags)
		buf.put_8(number_of_parameters)
		buf.put_16(position_x)
		buf.put_16(position_y)
		
		for t in test_byte_operations:
			t.write(buf)
		for w in write_byte_operations:
			w.write(buf)
		for p in parameters:
			buf.put_16(p)
 
class TestFlag:
	var flag : int
	var value : int
	var operation : int
	
	func read(data : StreamPeerBuffer):
		flag = data.get_16()
		value = data.get_8()    
		operation  = data.get_8()
	
	func write(buf : StreamPeerBuffer):
		buf.put_16(flag)
		buf.put_8(value)
		buf.put_8(operation)
	
class WriteFlag:
	var flag : int
	var value : int
	var operation : int
	
	func read(data : StreamPeerBuffer):
		flag = data.get_16()
		value = data.get_8()    
		operation  = data.get_8()
	
	func write(buf : StreamPeerBuffer):
		buf.put_16(flag)
		buf.put_8(value)
		buf.put_8(operation)
