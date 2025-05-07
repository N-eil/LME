extends PanelContainer
@onready var parameter_prefab = load("res://ObjectParameterEdit.tscn")
@onready var byte_operation_prefab = load("res://ByteOperationUI.tscn")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var object : RCDObject
@onready var object_list = $VSplitContainer/HBoxContainer/ObjectTypeMenu
# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(203):  #Hardcoded max of 203 objects are supported
		var object_num = "0x%02X" % i
		object_list.add_item("%s  %s" % [object_num,Globals.OBJECT_REFERENCE[object_num]["name"]])

func set_object(o):
	object = o

func clear_old_parameters():
	for c in $VSplitContainer/HSplitContainer/VBoxContainer.get_children():
		if c is HSplitContainer:
			c.queue_free()

func display(display_object : RCDObject):
	clear_old_parameters()

	object_list.select(display_object.object_id)
	$VSplitContainer/HSplitContainer/VSplitContainer/ExtraNotes.text = Globals.OBJECT_REFERENCE[("0x%02X" % display_object.object_id)]["notes"] + "\n" + Globals.OBJECT_REFERENCE[("0x%02X" % object.object_id)]["write_flag_notes"]
	
	var param_desc = Globals.OBJECT_REFERENCE[("0x%02X" % display_object.object_id)]["parameter_descriptions"]
	var param_count = Globals.OBJECT_REFERENCE[("0x%02X" % display_object.object_id)]["parameter_count"]
	for i in range(param_count):
		var p = parameter_prefab.instantiate()
		p.get_child(0).text = "Parameter %2d" % (i) if (i >= param_desc.size() || param_desc[i].is_empty()) else param_desc[i].left(20)
		p.get_child(0).tooltip_text = "No details" if (i >= param_desc.size() ||  param_desc[i].is_empty()) else param_desc[i]
		p.get_child(0).mouse_filter = MOUSE_FILTER_PASS
		p.get_child(1).value = display_object.parameters[i] if display_object.parameters.size() > i else 0
		$VSplitContainer/HSplitContainer/VBoxContainer.add_child(p)

	for c in $VSplitContainer/HSplitContainer/VSplitContainer/VSplitContainer/TestFlagsUI.get_children():
		if c is HBoxContainer:
			c.queue_free()
	for c in $VSplitContainer/HSplitContainer/VSplitContainer/VSplitContainer/WriteFlagsUI.get_children():
		if c is HBoxContainer:
			c.queue_free()

	for test_op in display_object.test_byte_operations:
		var t = byte_operation_prefab.instantiate()
		t.prefill_info(test_op.flag, test_op.operation, test_op.value)
		$VSplitContainer/HSplitContainer/VSplitContainer/VSplitContainer/TestFlagsUI.add_child(t)
  
	for write_op in display_object.write_byte_operations:
		var w = byte_operation_prefab.instantiate()
		w.prefill_info(write_op.flag, write_op.operation, write_op.value, false)
		$VSplitContainer/HSplitContainer/VSplitContainer/VSplitContainer/WriteFlagsUI.add_child(w)
	
	size = Vector2(0,0) # This is supposed to resize I think?  Not sure

# Modifies the object that is passed in. Be careful!
func convert_data_to_object(new_object : RCDObject):
	var i = 0
	new_object.parameters = []
	new_object.test_byte_operations = []
	new_object.write_byte_operations = []
	for p in $VSplitContainer/HSplitContainer/VBoxContainer.get_children():
		if p is HSplitContainer:
			print(p.get_child(1).value)
			new_object.parameters.append(p.get_child(1).value)
			i += 1
	new_object.number_of_parameters = i
	new_object.object_id = object_list.get_selected_id()
	
	i = 0
	for o in $VSplitContainer/HSplitContainer/VSplitContainer/VSplitContainer/TestFlagsUI.get_children():
		if o is HBoxContainer:
			new_object.test_byte_operations.append(o.store_as_operation())
			i += 1
	new_object.number_of_test_flags = i
	
	i = 0
	for o in $VSplitContainer/HSplitContainer/VSplitContainer/VSplitContainer/WriteFlagsUI.get_children():
		if o is HBoxContainer:
			new_object.write_byte_operations.append(o.store_as_operation())
			i += 1  
	new_object.number_of_write_flags = i
	
	# TODO: Allow editing object positions
#    if "position_x" in new_object:
#        new_object.position_x = 0
#        new_object.position_y = 0


func _on_SaveButton_pressed():
	convert_data_to_object(object)


func _on_ObjectTypeMenu_item_selected(index):
	object.object_id = index
	display(object)


func _on_add_test_flag_button_pressed():
	var t = byte_operation_prefab.instantiate()
	t.prefill_info(0, 0, 0, true, true)
	$VSplitContainer/HSplitContainer/VSplitContainer/VSplitContainer/TestFlagsUI.add_child(t)


func _on_add_write_flag_button_pressed():
	var t = byte_operation_prefab.instantiate()
	t.prefill_info(0, 0, 0, false, true)
	$VSplitContainer/HSplitContainer/VSplitContainer/VSplitContainer/WriteFlagsUI.add_child(t)


func _on_to_file_button_pressed():
	$SaveObjectDialog.popup()

func _on_from_file_button_pressed():
	$LoadObjectDialog.popup()

func _on_load_object_dialog_file_selected(path):
	display(ResourceLoader.load(path))

func _on_save_object_dialog_file_selected(path):
	var saving_object := RCDObject.new()
	convert_data_to_object(saving_object)
	ResourceSaver.save(saving_object, path)
