extends Node2D

signal highlight_clicked

var BASE_COLOR:Color = Color(0.2,0.2,0.8)
var SELECTED_COLOR:Color = Color(0.7,0.2,0.8)
var color:Color = BASE_COLOR

var BASE_WIDTH:float = 4.0
var SELECTED_WIDTH:float = 8.0
var width:float = BASE_WIDTH


var prev_cursor

# Called when the node enters the scene tree for the first time.
func _ready():
    var _err = $Area2D.connect("mouse_entered", self, "on_enter_zone")
    _err = $Area2D.connect("mouse_exited", self, "on_leave_zone")
    _err = $Area2D.connect("input_event", self, "on_event")

func on_event(_viewport, event, _shape_idx):
    if (event is InputEventMouseButton && event.pressed):
        print("Object picked!")
        emit_signal("highlight_clicked")
        
func on_enter_zone():
    print("Mouse entered!")
    
    prev_cursor = Input.get_current_cursor_shape()
    Input.set_default_cursor_shape(Input.CURSOR_ARROW)
    color = SELECTED_COLOR
    width = SELECTED_WIDTH
    
    update()

func on_leave_zone():
    
    Input.set_default_cursor_shape(prev_cursor)
    color = BASE_COLOR
    width = BASE_WIDTH
    update()
    
func _draw():
    draw_arc(Vector2(0,0), 60.0, 0, 2*PI, 32, color, width, true)
