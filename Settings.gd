extends ColorRect

signal laser_toggled
signal npcs_toggled

@onready var NPCsBtn = $CenterContainer/VBoxContainer/HBoxContainer3/NPCsEnabled

# used when pressing 'cancel'
var original_state_laser
var original_state_npcs

func _ready():
	visible = false
	modulate = Color(1.0,1.0,1.0,0.0)
	
	var _err = $CenterContainer/VBoxContainer/HBoxContainer2/exit.connect("pressed", Callable(self, "on_exit"))
	_err = $CenterContainer/VBoxContainer/HBoxContainer2/ok.connect("pressed", Callable(self, "on_ok"))
	_err = $CenterContainer/VBoxContainer/HBoxContainer2/cancel.connect("pressed", Callable(self, "on_cancel"))
	_err = $CenterContainer/VBoxContainer/HBoxContainer/LaserEnabled.connect("toggled", Callable(self, "on_toggle_laser"))
	_err = NPCsBtn.connect("toggled", Callable(self, "on_toggle_npcs"))

	
func display(msg = null):
	
	original_state_laser = $CenterContainer/VBoxContainer/HBoxContainer/LaserEnabled.pressed
	original_state_npcs = NPCsBtn.pressed
	
	if msg:
		$CenterContainer/VBoxContainer/Label.text = msg
		
	visible = true
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate:a", null, 1.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
	$Tween.start()


func on_toggle_laser(state):

	emit_signal("laser_toggled", state)

func on_toggle_npcs(state):

	emit_signal("npcs_toggled", state)

func on_ok():
	
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
	$Tween.start()
	
	await $Tween.tween_all_completed
	
	visible = false

func on_cancel():
	
	$CenterContainer/VBoxContainer/HBoxContainer/LaserEnabled.button_pressed = original_state_laser
	on_toggle_laser(original_state_laser)
	NPCsBtn.button_pressed = original_state_npcs
	on_toggle_npcs(original_state_npcs)
	
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
	$Tween.start()
	
	await $Tween.tween_all_completed

	visible = false


func on_exit():
	$ModalMessage.open()
	var output = await $ModalMessage.on_choice
	
	if output == "ok":
		get_tree().quit()
