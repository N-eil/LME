extends Window

@onready var layer_display = $LayerCompositeDisplay

func _ready():
	Messages.connect("edit_type_changed", _on_edit_type_changed)
	Messages.connect("new_art_palette", _on_new_art_palette)

func convert_to_layer_data() -> LayerArtPortion:
	return layer_display._layer_holder.get_child(0).to_display

func _on_edit_type_changed(e):
	visible = (e == Globals.EditType.ART || e == Globals.EditType.ART_COPY)
#
	#$Node2D/LayerPortionDisplay.to_display = LayerArtPortion.new(20,20)
	#TileSetLoader.make_tileset(Globals.make_graphics_filename("map01_1.png"))
	#$Node2D/LayerPortionDisplay.active_tileset = TileSetLoader.current_tileset
	#$Node2D/LayerPortionDisplay.display_portion()
	#$Node2D/LayerPortionDisplay.get_child(0).set_process_unhandled_input(visible)

func _on_new_art_palette(e):
	layer_display.rebuild_tileset(e)
	#layer_display._layer_holder.get_child(0).display_portion()
	layer_display.SublayerSelect.fill_layer_UI(layer_display._layer_holder.get_children())

func set_sketchpad_art_with_backup(new_display : LayerArtPortion):
	_on_save_object_dialog_file_selected("user://sketch-backup.tres")
	set_sketchpad_art(new_display)

func set_sketchpad_art(new_display : LayerArtPortion):
	layer_display.generate_from_layer_portion(new_display)
	layer_display.position = Vector2(64,64)

func _on_load_object_dialog_file_selected(path):
	var new_display : LayerArtPortion = ResourceLoader.load(path)
	set_sketchpad_art_with_backup(new_display)
	Messages.emit_signal("new_art_palette", new_display.tilesheet_filename)

func _on_save_object_dialog_file_selected(path):
	if layer_display._layer_holder.get_child_count() == 0:
		printerr("Saved art, but there was nothing to save!")
		return
	var layer_portion_data : LayerArtPortion = convert_to_layer_data()
	ResourceSaver.save(layer_portion_data, path)

func _on_save_button_pressed():
	$SaveObjectDialog.popup()

func _on_load_button_pressed():
	$LoadObjectDialog.popup()

func _on_create_button_pressed():
	var new_art_width = $Control/VBoxContainer/WidthSetter.value
	var new_art_height = $Control/VBoxContainer/HeightSetter.value
	var new_art_layers = $Control/VBoxContainer/LayerCountSetter.value - 1 # The first sublayer comes with the initialization
	
	var new_art_portion = LayerArtPortion.new(new_art_width, new_art_height)
	for i in range(new_art_layers):
		new_art_portion.add_empty_sublayer()

	layer_display.generate_from_layer_portion(new_art_portion)
