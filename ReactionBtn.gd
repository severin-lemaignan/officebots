extends TextureButton

export(String) var reaction

signal reaction

func _ready():
    connect("button_up", self, "emit_signal", ["reaction", reaction])

