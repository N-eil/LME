extends Resource
class_name Field
var name_size: int
var objects_count: int
var name: Array  # Array of bytes. Need to decode as UTF16 for text. Does nothing, do not name a zone by writing to this
var objects: Array [RCDObject]
var rooms: Array [RCDRoom]

var room_count : int
var zone_id : int

func _init(id):
	zone_id = id

func linear_order_to_internal_position(linear_number : int):
	for r in range(room_count):
		for s in range(rooms[r].screen_count):
			if linear_number == 0:
				return Vector3i(zone_id,r, s)
			linear_number -= 1
	printerr("Asked for a position of a screen outside the field!")
	return Vector3i(-1,-1,-1)

func internal_position_to_linear_order(pos : Vector3i):
	var linear_number = 0
	for r in range(room_count):
		for s in range(rooms[r].screen_count):
			if r == pos.y and s == pos.z:
				return linear_number
			linear_number += 1
	printerr("Asked for linear order of a screen outside the field!")
	return -1

func add_screen(room_id): #TODO: Add screens to other places than just directly right
	if (room_id >= room_count):
		room_count += 1
		room_id = room_count - 1
		rooms.append(RCDRoom.new(room_id))
	rooms[room_id].add_screen(zone_id)

func read(data : StreamPeerBuffer, msd : MSDMap):
	room_count = msd.room_count
	
	name_size = data.get_8()
	objects_count = data.get_16()
	name = data.get_data(name_size)[1]
	
	for i in range(objects_count):
		var o = RCDObject.new()
		o.read(data, false)
		objects.append(o)
		
	for i in range(room_count):
		var r = RCDRoom.new(i)
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
