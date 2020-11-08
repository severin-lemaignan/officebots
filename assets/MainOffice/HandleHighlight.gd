extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var BASE_COLOR:Color = Color(0.8,0.8,0.0)
var SELECTED_COLOR:Color = Color(0.8,0.2,0.0)

var color:Color = BASE_COLOR

# Called when the node enters the scene tree for the first time.
func _ready():
    $Area2D.connect("mouse_entered", self, "on_enter_zone")
    $Area2D.connect("mouse_exited", self, "on_leave_zone")


func on_enter_zone():
    print("Mouse entered!")
    color = SELECTED_COLOR
    update()

func on_leave_zone():
    color = BASE_COLOR
    update()
    
func _draw():
    draw_arc(Vector2(0,0), 60.0, 0, 2*PI, 32, color, 2, true)
