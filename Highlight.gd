extends Node2D

signal highlight_clicked

#var BASE_COLOR:Color = Color(0.2,0.2,0.8) # blue
#var SELECTED_COLOR:Color = Color(0.7,0.2,0.8) # purple
var BASE_COLOR:Color = Color(0.7,0.7,0.2)

var hover = false
var size = 1.0

var prev_cursor

# Called when the node enters the scene tree for the first time.
func _ready():
	var _err = $Area2D.connect("mouse_entered", self, "on_enter_zone")
	_err = $Area2D.connect("mouse_exited", self, "on_leave_zone")
	_err = $Area2D.connect("input_event", self, "on_event")

func set_scale(scale):
	$Area2D/CollisionShape2D.scale = Vector2(scale,scale)
	size = scale
	
func on_event(_viewport, event, _shape_idx):
	if (event is InputEventMouseButton && event.pressed):
		emit_signal("highlight_clicked")
		
func on_enter_zone():
	
	hover = true
	prev_cursor = Input.get_current_cursor_shape()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	update()

func on_leave_zone():
	
	hover = false
	Input.set_default_cursor_shape(prev_cursor)
	update()
	
func _draw():
	
	if hover:
		draw_circle(Vector2(0,0), 60.0 * size, BASE_COLOR)
		
	else:
		# dont draw anything if not hovering
		pass
