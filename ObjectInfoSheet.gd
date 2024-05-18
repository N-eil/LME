extends PanelContainer
@onready var parameter_prefab = load("res://ObjectParameterEdit.tscn")
@onready var byte_operation_prefab = load("res://ByteOperationUI.tscn")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var object
@onready var object_list = $VSplitContainer/HBoxContainer/ObjectTypeMenu
# Called when the node enters the scene tree for the first time.
func _ready():

	for i in range(203):  #Hardcoded max of 203 objects are supported
		object_list.add_item(("0x%02X" % i))

func set_object(o):
	object = o

func display():
	for c in $VSplitContainer/HSplitContainer/VBoxContainer.get_children():
		if c is HSplitContainer:
			c.queue_free()

	size = Vector2(0,0) # This is supposed to resize I think?  Not sure

	$VSplitContainer/HSplitContainer/VSplitContainer/ExtraNotes.text = Globals.OBJECT_REFERENCE[("0x%02X" % object.object_id)]["notes"] + "\n" + Globals.OBJECT_REFERENCE[("0x%02X" % object.object_id)]["write_flag_notes"]

	var i = 0
	var param_desc = Globals.OBJECT_REFERENCE[("0x%02X" % object.object_id)]["parameter_descriptions"]
	for parameter in object.parameters:
		var p = parameter_prefab.instantiate()
		p.get_child(0).text = "Parameter %2d" % (i)
		p.get_child(0).tooltip_text = "No details" if param_desc.is_empty() else param_desc[i]
		p.get_child(0).mouse_filter = MOUSE_FILTER_PASS
		p.get_child(1).value = parameter
		$VSplitContainer/HSplitContainer/VBoxContainer.add_child(p)
		i += 1

	object_list.select(object.object_id)

	for c in $VSplitContainer/HSplitContainer/VSplitContainer/VSplitContainer/TestFlagsUI.get_children():
		if c is HBoxContainer:
			c.queue_free()
	for c in $VSplitContainer/HSplitContainer/VSplitContainer/VSplitContainer/WriteFlagsUI.get_children():
		if c is HBoxContainer:
			c.queue_free()
		
	for test_op in object.test_byte_operations:
		var t = byte_operation_prefab.instantiate()
		t.prefill_info(test_op.flag, test_op.operation, test_op.value)
		$VSplitContainer/HSplitContainer/VSplitContainer/VSplitContainer/TestFlagsUI.add_child(t)
  
	for write_op in object.write_byte_operations:
		var w = byte_operation_prefab.instantiate()
		w.prefill_info(write_op.flag, write_op.operation, write_op.value, false)
		$VSplitContainer/HSplitContainer/VSplitContainer/VSplitContainer/WriteFlagsUI.add_child(w)
	

func _on_SaveButton_pressed():
	var i = 0

	for p in $VSplitContainer/HSplitContainer/VBoxContainer.get_children():
		if p is HSplitContainer:
			object.parameters[i] = p.get_child(1).value
			i += 1
	object.number_of_parameters = i
	object.object_id = object_list.get_selected_id()
	
	i = 0
	for o in $VSplitContainer/HSplitContainer/VSplitContainer/VSplitContainer/TestFlagsUI.get_children():
		if o is HBoxContainer:
			object.test_byte_operations[i] = o.store_as_operation()
			i += 1
	object.number_of_test_flags = i
	
	i = 0
	for o in $VSplitContainer/HSplitContainer/VSplitContainer/VSplitContainer/WriteFlagsUI.get_children():
		if o is HBoxContainer:
			object.write_byte_operations[i] = o.store_as_operation()
			i += 1  
	object.number_of_write_flags = i
	
	# TODO: Allow editing object positions
#    if "position_x" in object:
#        object.position_x = 0
#        object.position_y = 0


func _on_ObjectTypeMenu_item_selected(index):
	pass
#    object.object_id = index
