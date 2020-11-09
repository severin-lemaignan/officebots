extends ColorRect

signal on_choice


func _ready():
    visible = false
    modulate = Color(1.0,1.0,1.0,0.0)
    
    $CenterContainer/VBoxContainer/HBoxContainer/Ok.connect("pressed", self, "on_ok")
    $CenterContainer/VBoxContainer/HBoxContainer/Cancel.connect("pressed", self, "on_cancel")
    
func show(msg = null):
    
    if msg:
        $CenterContainer/VBoxContainer/Label.text = msg
        
    visible = true
    $Tween.remove_all()
    $Tween.interpolate_property(self, "modulate:a", null, 1.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
    $Tween.start()


func on_ok():

    modulate = Color(1.0,1.0,1.0,0.0)
    visible = false
    
    emit_signal("on_choice", "ok")

func on_cancel():
    
    
    modulate = Color(1.0,1.0,1.0,0.0)
    visible = false
    
    emit_signal("on_choice", "cancel")
