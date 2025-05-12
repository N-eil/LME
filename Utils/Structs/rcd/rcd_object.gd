extends Resource
class_name RCDObject

@export var object_id : int
@export var number_of_test_flags : int
@export var number_of_write_flags : int
@export var number_of_parameters : int
@export var has_position : bool = false
@export var position_x : int
@export var position_y : int
@export var test_byte_operations : Array
@export var write_byte_operations : Array
@export var parameters : Array 

func _to_string():
	var object_name = ("0x%02X" % object_id)
	return object_name + " " + Globals.OBJECT_REFERENCE[object_name]["name"]

func read(data : StreamPeerBuffer, with_position : bool = false):
	object_id  = data.get_16()
	var number_of_flags = data.get_u8()
	number_of_test_flags = number_of_flags >> 4
	number_of_write_flags  = number_of_flags & 15
	number_of_parameters = data.get_8()
	
	has_position = with_position
	if with_position:
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

	if has_position:
		buf.put_16(position_x)
		buf.put_16(position_y)
	
	for t in test_byte_operations:
		t.write(buf)
	for w in write_byte_operations:
		w.write(buf)
	for p in parameters:
		buf.put_16(p)
