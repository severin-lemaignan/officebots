extends ColorRect

signal on_choice


func _ready():
	visible = false
	modulate = Color(1.0,1.0,1.0,0.0)
	
	var _err = $CenterContainer/VBoxContainer/HBoxContainer/Ok.connect("pressed", Callable(self, "on_ok"))
	_err = $CenterContainer/VBoxContainer/HBoxContainer/Cancel.connect("pressed", Callable(self, "on_cancel"))
	
func open(msg = null):
	
	if msg:
		$CenterContainer/VBoxContainer/Label.text = msg
		
	visible = true
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)


func on_ok():

	modulate = Color(1.0,1.0,1.0,0.0)
	visible = false
	
	on_choice.emit("ok")

func on_cancel():
	
	
	modulate = Color(1.0,1.0,1.0,0.0)
	visible = false
	
	on_choice.emit("cancel")
