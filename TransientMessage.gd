extends Label

func _ready():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 5.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
