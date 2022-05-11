extends TileMap

var width = 32
var height = 24

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func _input(event):
    if event is InputEventMouseButton and event.pressed:
        _on_tilemap_click(event)
    
func _on_tilemap_click(event):
    var local_position = to_local(event.position)
    var map_position = world_to_map(local_position)
    if (map_position.x < 0 or map_position.y < 0 or map_position.x >= width or map_position.y >= height):
        return
    get_parent().get_parent().get_parent().get_parent().cell_clicked(self, map_position)
    
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
