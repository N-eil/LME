extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var object setget set_object
var editor_ref

func set_object(o):
    $Node2D/IDTag.text = ("0x%02X" % o.object_id)
    object = o
    

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass


func _on_ObjectPlaceholder_input_event(viewport, event, shape_idx):
    if event is InputEventMouseButton and event.pressed:


        # TODO: The goal of all this code is to click only the front object of a stack and move it to the back.
        #       This doesn't work since it seems like click order on overlapping nodes is arbitrary?
        var click_count = event.get_meta("clickcount")
        if not click_count:
            click_count = 0
        print(click_count)
        click_count += 1
        event.set_meta("clickcount", click_count)
        if click_count > 1:
            return
        print("cllicked object")
        get_parent().move_child(self, 0)
        editor_ref.show_object_edit_menu(object)
