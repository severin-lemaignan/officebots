extends Control

@onready var url_field = $CenterContainer/HBoxContainer/MultiPlayerBtn/CenterContainer/MultiplayerGame/URL
@onready var single_btn = $CenterContainer/HBoxContainer/SinglePlayerBtn
@onready var multi_btn = $CenterContainer/HBoxContainer/MultiPlayerBtn

signal on_mode_set

func _ready():
	
	single_btn.button_up.connect(on_single_player)
	multi_btn.button_up.connect(on_multi_player)

func on_single_player():
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	
	await tween.finished
	
	visible = false
	
	on_mode_set.emit(null)
	
func on_multi_player():
	var url = url_field.text
	
	if url == "":
		url_field.placeholder_text = "Please set the server address first!"
		return
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	await tween.finished
	
	visible = false
	
	on_mode_set.emit(url)
