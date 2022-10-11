extends Label


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate:a", null, 0.0, 5.5, Tween.TRANS_QUART, Tween.EASE_IN)
	$Tween.start()



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
