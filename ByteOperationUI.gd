extends HBoxContainer

class TestFlag:  # TODO: find some way to store the class centrally?
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


const TEST_OPERATIONS = [
	"Equals",
	"Less or equals",
	"Greater or equals",
	"Bitwise AND nonzero",
	"Bitwise OR nonzero",
	"Bitwise XOR nonzero",
	"Flag is zero",
	"Not equal",
	"Greater than",
	"Less than",
	"Bitwise AND zero",
	"Bitwise OR zero",
	"Bitwise XOR zero",
	"Flag is nonzero"
]
	
const WRITE_OPERATIONS = [
	"Assignment",
	"Addition",
	"Subtraction",
	"Multiplication",
	"Division", 
	"Bitwise AND",
	"Bitwise OR",
	"Bitwise XOR"    
]

var operations_list

func test_value_to_index(value):
	if value < 7:
		return value
	return (value - 0x40) + 7
	
func index_to_test_value(index):
	if index < 7:
		return index
	return (index - 7) + 0x40

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func prefill_info(flag, operation, value, is_test = true, is_index = false):
	$FlagInput.value = flag
	$ValueInput.value = value
	
	operations_list = TEST_OPERATIONS if is_test else WRITE_OPERATIONS
	for o in operations_list:
		$OperationInput.add_item(o)
	$OperationInput.select(operation if is_index else test_value_to_index(operation))

func store_as_operation():
	var f = TestFlag.new()
	f.flag = $FlagInput.value
	f.value = $ValueInput.value
	f.operation = index_to_test_value($OperationInput.get_selected_id())
	return f

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
