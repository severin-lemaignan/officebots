extends Control

@onready var button = $speech_bubble/Label/Button

enum ButtonType {NONE, OK, NEXT}

signal done_speaking

var is_speaking = false

func _ready():
	
	# make the speech bubble initially transparent
	modulate.a = 0
	
	button.visible = false

func flip_left():
	$speech_bubble.flip_h = false

func flip_right():
	$speech_bubble.flip_h = true

func maskaway():
	if is_speaking:
		return
		
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.1)


func typing():
	$speech_bubble/Label.text = ""
	$speech_bubble/AnimatedDots.visible = true
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.1)
	
func say(text, button_type = ButtonType.NONE):
	
	$speech_bubble/AnimatedDots.visible = false
	
	match button_type:
		ButtonType.NONE:
			button.visible = false
		ButtonType.OK:
			button.visible = true
			button.text = "Ok"
		ButtonType.NEXT:
			button.visible = true
			button.text = "Next"

	$speech_bubble/Label.text = text
	
	if text.length() < 20:
		$speech_bubble/Label.get("theme_override_fonts/font").set_size(36)
	else:
		$speech_bubble/Label.get("theme_override_fonts/font").set_size(24)
	
	is_speaking = true
	
	var wait_time = 2 + text.length() / 8
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.1)

	if button_type == ButtonType.NONE:
		# dismiss the bubble after set time
		await get_tree().create_timer(wait_time).timeout
	else:
		# wait for a click
		await button.pressed
	
	tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	is_speaking = false
	emit_signal("done_speaking")
