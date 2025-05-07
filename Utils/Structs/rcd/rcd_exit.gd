extends Resource
class_name Exit

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

func _to_string():
	return "Exit to %s %s %s" % [zone_id, room_id, screen_id]

#class ObjectWithoutPosition:
	#var object_id : int
	#var number_of_test_flags : int
	#var number_of_write_flags : int
	#var number_of_parameters : int
	#var test_byte_operations : Array
	#var write_byte_operations : Array
	#var parameters : Array
	#
	#func read(data : StreamPeerBuffer):
		#object_id  = data.get_16()
		#var number_of_flags = data.get_u8()
		#number_of_test_flags = number_of_flags >> 4
		#number_of_write_flags  = number_of_flags & 15
		#number_of_parameters = data.get_8()
#
		## Code that surveys the parameters and flags of all objects in the game. Useful to build a list of what is valid and what is not	
##		var hex_id = ("0x%02X" % object_id)
##		if hex_id in Globals.all_nonposition_objects:
##			if number_of_parameters not in Globals.all_nonposition_objects[hex_id]["parameter_count"]:
##				Globals.all_nonposition_objects[hex_id]["parameter_count"].append(number_of_parameters)
##			if number_of_test_flags not in Globals.all_nonposition_objects[hex_id]["testflag_count"]:
##				Globals.all_nonposition_objects[hex_id]["testflag_count"].append(number_of_test_flags)
##			if number_of_write_flags not in Globals.all_nonposition_objects[hex_id]["writeflag_count"]:
##				Globals.all_nonposition_objects[hex_id]["writeflag_count"].append(number_of_write_flags)
##		else:
##			Globals.all_nonposition_objects[hex_id] = {"parameter_count": [number_of_parameters], "testflag_count": [number_of_test_flags], "writeflag_count": [number_of_write_flags]}
		#
		#
		#for i in range(number_of_test_flags):
			#var o = TestFlag.new()
			#o.read(data)
			#test_byte_operations.append(o)
		#
		#for i in range(number_of_write_flags):
			#var o = WriteFlag.new()
			#o.read(data)
			#write_byte_operations.append(o)
			#
		#for i in range(number_of_parameters):
			#var o = data.get_16()
			#parameters.append(o)
			#
	#func write(buf : StreamPeerBuffer):
		#buf.put_16(object_id)
		#var number_of_flags = ((number_of_test_flags << 4) + number_of_write_flags)
		#buf.put_8(number_of_flags)
		#buf.put_8(number_of_parameters)
		#
		#for t in test_byte_operations:
			#t.write(buf)
		#for w in write_byte_operations:
			#w.write(buf)
		#for p in parameters:
			#buf.put_16(p)
