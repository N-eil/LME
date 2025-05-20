extends VSplitContainer

signal activated(data : TreeItem)

@export var composite_display : Node2D 
@export var active_room : Resource :
	set(s):
		if s is MSDRoom:
			active_room = s
			$LayerAdder/HBoxContainer.visible = true
		elif s is Layer:
			active_room = s
			$LayerAdder/HBoxContainer.visible = false
		else:
			printerr("Attached SubLayer adder UI to something without sublayers!")

@onready var selector = $SublayerSelector

func _ready():
	selector.activated.connect(relay_activated_signal)

func relay_activated_signal(d):
	activated.emit(d)

func update_sublayer_info(room : Resource, layer_nodes : Array[Node]):
	active_room = room
	return selector.fill_layer_UI(layer_nodes)

func _on_add_sublayer_button_pressed():
	if selector.current_selected_layer:
		selector.current_selected_layer.add_sublayer(Sublayer.create_empty(selector.current_selected_layer.layer_width, selector.current_selected_layer.layer_height), int($LayerAdder/HBoxContainer2/Ordering.text)-1)
		composite_display.generate()

func _on_add_layer_button_pressed():
	active_room.add_layer(Layer.create_empty(int($LayerAdder/HBoxContainer/Width.text), int($LayerAdder/HBoxContainer/Height.text)), int($LayerAdder/HBoxContainer/Ordering.text)-1)
	composite_display.generate()
