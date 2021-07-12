extends Area

var target_player = null 
var location = "Tabletennis room "
signal target_detected
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    connect("body_entered",self,"on_body_entered")

func on_body_entered(body): 
    print("in body entered de la target zone")

    if target_player and body == target_player : 
        emit_signal("target_detected",target_player)
        print("signal emited 1")
