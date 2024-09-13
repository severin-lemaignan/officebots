extends TextureButton

@export var reaction: String

signal reaction

func _ready():
	connect("button_up", Callable(self, "emit_signal").bind("reaction", reaction))

