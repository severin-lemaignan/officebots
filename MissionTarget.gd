extends Area

var target_player = null 
var target_object = null 

signal target_detected
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    connect("body_entered",self,"on_body_entered")

func on_body_entered(body): 
   
    if target_player and body == target_player : 
        emit_signal("target_detected",target_player)
    elif target_object and body == target_object: 
        emit_signal("target_detected",target_player)
        
