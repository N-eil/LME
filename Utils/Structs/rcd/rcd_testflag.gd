extends Resource
class_name TestFlag
@export var flag : int
@export var value : int
@export var operation : int

func read(data : StreamPeerBuffer):
	flag = data.get_16()
	value = data.get_8()    
	operation  = data.get_8()

func write(buf : StreamPeerBuffer):
	buf.put_16(flag)
	buf.put_8(value)
	buf.put_8(operation)
