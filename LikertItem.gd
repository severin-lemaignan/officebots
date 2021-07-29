extends Control

signal selected


# Called when the node enters the scene tree for the first time.
func _ready():
    var _err = $"0".connect("pressed", self, "on_option_selected")
    _err = $"1".connect("pressed", self, "on_option_selected")
    _err = $"2".connect("pressed", self, "on_option_selected")
    _err = $"3".connect("pressed", self, "on_option_selected")
    _err = $"4".connect("pressed", self, "on_option_selected")

func on_option_selected():
    emit_signal("selected", get_answer())

func set_question(text):
    $Label.text = text

func is_valid():
    return $"0".group.get_pressed_button() == null
    
func get_answer():
    return int($"0".group.get_pressed_button().name)

func focus(state):
    if state:
        $"2".grab_focus()
    else:
        $"0".release_focus()
        $"1".release_focus()
        $"2".release_focus()
        $"3".release_focus()
        $"4".release_focus()
