extends TextureButton

@export var reaction: String

signal user_reaction

func _ready():
	connect("button_up", Callable(self, "emit_signal").bind("user_reaction", reaction))
