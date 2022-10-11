extends Control

export (Texture) var normal
export (Texture) var pressed

export (bool) var timer = true

signal pressed
signal unpressed

var active : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$RadialProgress.visible = false
	
	$button.texture_normal = normal
	$button.texture_hover = pressed
	$button.texture_pressed = pressed
	
	$button.connect("pressed", self, "on_pressed")
	$RadialProgress.connect("timeout", self, "on_timeout")

func on_pressed():
	
	active = true
	emit_signal("pressed")
	$button.pressed = true
	
	if timer:
		$RadialProgress.visible = true
		$RadialProgress.start(5)

func on_timeout():
	
	# still active? (eg, not pre-empted by a click on another button?)
	if active:
		stop()
		emit_signal("unpressed")

func stop():
	active = false
	$button.pressed = false
	$RadialProgress.visible = false
	$RadialProgress.reset()

