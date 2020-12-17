extends ColorRect

signal on_toggle_laser

# used when pressing 'cancel'
var original_state_laser

func _ready():
    visible = false
    modulate = Color(1.0,1.0,1.0,0.0)
    
    var _err = $CenterContainer/VBoxContainer/HBoxContainer2/exit.connect("pressed", self, "on_exit")
    _err = $CenterContainer/VBoxContainer/HBoxContainer2/ok.connect("pressed", self, "on_ok")
    _err = $CenterContainer/VBoxContainer/HBoxContainer2/cancel.connect("pressed", self, "on_cancel")
    _err = $CenterContainer/VBoxContainer/HBoxContainer/LaserEnabled.connect("toggled", self, "on_toggle_laser")
    
func show(msg = null):
    
    original_state_laser = $CenterContainer/VBoxContainer/HBoxContainer/LaserEnabled.pressed
    
    if msg:
        $CenterContainer/VBoxContainer/Label.text = msg
        
    visible = true
    $Tween.remove_all()
    $Tween.interpolate_property(self, "modulate:a", null, 1.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
    $Tween.start()


func on_toggle_laser(state):

    emit_signal("on_toggle_laser", state)

func on_ok():
    
    $Tween.remove_all()
    $Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
    $Tween.start()
    
    yield($Tween,"tween_all_completed")
    
    visible = false

func on_cancel():
    
    $CenterContainer/VBoxContainer/HBoxContainer/LaserEnabled.pressed = original_state_laser
    on_toggle_laser(original_state_laser)
    
    $Tween.remove_all()
    $Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
    $Tween.start()
    
    yield($Tween,"tween_all_completed")

    visible = false


func on_exit():
    $ModalMessage.show()
    var output = yield($ModalMessage, "on_choice")
    
    if output == "ok":
        get_tree().quit()
