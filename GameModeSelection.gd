extends Control

onready var url_field = $CenterContainer/HBoxContainer/MultiPlayerBtn/CenterContainer/MultiplayerGame/URL
onready var single_btn = $CenterContainer/HBoxContainer/SinglePlayerBtn
onready var multi_btn = $CenterContainer/HBoxContainer/MultiPlayerBtn

signal on_mode_set

func _ready():
    
    single_btn.connect("button_up",self, "on_single_player")
    multi_btn.connect("button_up",self, "on_multi_player")

func on_single_player():
    
    $Tween.remove_all()
    $Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
    $Tween.start()
    yield($Tween, "tween_all_completed")
    
    visible = false
    
    emit_signal("on_mode_set", null)
    
func on_multi_player():
    var url = url_field.text
    
    if url == "":
        url_field.placeholder_text = "Please set the server address first!"
        return
    
    $Tween.remove_all()
    $Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
    $Tween.start()
    yield($Tween, "tween_all_completed")
    
    visible = false
    
    emit_signal("on_mode_set", url)
