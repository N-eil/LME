extends Tree

signal activated(data : TreeItem)

var current_selected_treeitem : TreeItem = null
var current_selected_layer

func fill_layer_UI(layer_nodes : Array[Node]):
	clear()
	var root = create_item()
	
	var outer_temp_index := 0
	for layer_node in layer_nodes:
		outer_temp_index += 1
		var layer = layer_node.to_display.stored_layer
		var tree_layer = create_item(root)
		tree_layer.set_text(0, "LAYER " + str(outer_temp_index) +" - Height: " + str(layer.layer_height) + " Width: " + str(layer.layer_width) )
		tree_layer.set_selectable(0, true)
		tree_layer.set_selectable(1, false)
		tree_layer.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
		tree_layer.set_checked(1, true)
		tree_layer.set_tooltip_text(1, "Show/Hide")
		tree_layer.set_editable(1, true)
		tree_layer.set_metadata(0, layer)
		if layer.is_prime_layer:
			tree_layer.set_custom_color(0, Color.CYAN)

		var temp_index := 0
		for sublayer_node in layer_node.get_children():
			temp_index += 1
			var tree_sublayer = create_item(tree_layer)
			tree_sublayer.set_text(0, "Sublayer " + str(temp_index))
			tree_sublayer.set_selectable(0, true)
			tree_sublayer.set_selectable(1, false)
			tree_sublayer.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
			tree_sublayer.set_checked(1, true)
			tree_sublayer.set_tooltip_text(1, "Show/Hide")
			tree_sublayer.set_editable(1, true)
			tree_sublayer.set_metadata(0, sublayer_node)

	grow_vertical = 1

func select_layer(item : TreeItem):
	if current_selected_treeitem:
		current_selected_treeitem.clear_custom_bg_color(0)
	
	current_selected_treeitem = item
	
	current_selected_treeitem.set_custom_bg_color(0, Color.RED)
	
	if current_selected_treeitem.get_metadata(0) is TileMap:
		current_selected_layer = current_selected_treeitem.get_parent().get_metadata(0)
		activated.emit(current_selected_treeitem)
	else:
		current_selected_layer = current_selected_treeitem.get_metadata(0)

func _on_item_edited():
	var checked_layer : TreeItem = get_edited()
	var checked_metadata = checked_layer.get_metadata(0)
	if checked_metadata is TileMap:

		var screen_layer = checked_metadata as TileMap
		screen_layer.visible = checked_layer.is_checked(1)
		if screen_layer.visible:
			select_layer(checked_layer)
	else:
		for sublayer in checked_layer.get_children():
			var sublayer_metadata = sublayer.get_metadata(0) as TileMap
			sublayer_metadata.visible = checked_layer.is_checked(1)
			sublayer.set_checked(1, checked_layer.is_checked(1))

func _on_item_selected():
	select_layer(get_selected())
