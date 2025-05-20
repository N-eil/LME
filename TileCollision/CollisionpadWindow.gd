extends Window

@onready var collision_map = $CollisionTilemap

func _ready():
	Messages.connect("edit_type_changed", _on_edit_type_changed)

#func convert_to_layer_data() -> LayerArtPortion:
	#return layer_display._layer_holder.get_child(0).to_display

func _on_edit_type_changed(e):
	visible = (e == Globals.EditType.COLLISION)
	collision_map.set_process_unhandled_input(visible)
	#if visible:
		#collision_map.blank_from_dimensions(Vector2i(10,15))

	#$Node2D/LayerPortionDisplay.to_display = LayerArtPortion.new(20,20)
	#TileSetLoader.make_tileset(Globals.make_graphics_filename("map01_1.png"))
	#$Node2D/LayerPortionDisplay.active_tileset = TileSetLoader.current_tileset
	#$Node2D/LayerPortionDisplay.display_portion()
	#$Node2D/LayerPortionDisplay.get_child(0).set_process_unhandled_input(visible)

func set_sketchpad_contents_with_backup(new_contents : Array[Array]):
	#_on_save_object_dialog_file_selected("user://hitmask-backup.tres")
	set_sketchpad_contents(new_contents)

func set_sketchpad_contents(new_contents : Array[Array]):
	collision_map.from_hitmask(new_contents)
	collision_map.position = Vector2(64,64)

func _on_load_object_dialog_file_selected(path):
	var hitmask_saver : HitmaskSaver = ResourceLoader.load(path)
	set_sketchpad_contents_with_backup(hitmask_saver.hitmask)

func _on_save_object_dialog_file_selected(path):
	var hitmask_saver : HitmaskSaver = HitmaskSaver.new()
	hitmask_saver.hitmask = collision_map.hitmask_data
	hitmask_saver.height = len(hitmask_saver.hitmask)
	hitmask_saver.width = len(hitmask_saver.hitmask[0])
	ResourceSaver.save(hitmask_saver, path)

func _on_save_button_pressed():
	$SaveObjectDialog.popup()

func _on_load_button_pressed():
	$LoadObjectDialog.popup()

func _on_create_button_pressed():
	# Yes, this swap is intentional
	var new_art_height = $Control/VBoxContainer/WidthSetter.value
	var new_art_width = $Control/VBoxContainer/HeightSetter.value

	collision_map.blank_from_dimensions(Vector2i(new_art_height, new_art_width))
