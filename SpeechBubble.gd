extends Control

onready var button = $speech_bubble/Label/Button

enum ButtonType {NONE, OK, NEXT}

signal done_speaking
var emotion = "no emotion "
var is_speaking = false

func _ready():
    
    # make the speech bubble initially transparent
    modulate.a = 0
    
    button.visible = false

func flip_left():
    $speech_bubble.flip_h = false

func flip_right():
    $speech_bubble.flip_h = true

func hide():
    if is_speaking:
        return
        
    $Tween.remove_all()
    $Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.1)
    $Tween.start()


func typing():
    $speech_bubble/Label.text = ""
    $speech_bubble/AnimatedDots.visible = true
    
    $Tween.remove_all()
    $Tween.interpolate_property(self, "modulate:a", null, 1.0, 0.1)
    $Tween.start()
    
func say(text, button_type = ButtonType.NONE):
    
    $speech_bubble/AnimatedDots.visible = false
    
    match button_type:
        ButtonType.NONE:
            button.visible = false
        ButtonType.OK:
            button.visible = true
            button.text = "Ok"
        ButtonType.NEXT:
            button.visible = true
            button.text = "Next"

    $speech_bubble/Label.text = text
    if text == ":happy:": 
        emotion = "happy"
    if text == ":smily:": 
        emotion = "smily"
    if text == ":laughing:": 
        emotion = "laughing"
    if text == ":confused:": 
        emotion = "confused"
    if text == ":bored:": 
        emotion = "bored"
    
    
    if text.length() < 20:
        $speech_bubble/Label.get("custom_fonts/font").set_size(36)
    else:
        $speech_bubble/Label.get("custom_fonts/font").set_size(24)
    
    is_speaking = true
    
    var wait_time = 2 + text.length() / 8
    
    $Tween.remove_all()
    $Tween.interpolate_property(self, "modulate:a", null, 1.0, 0.1)
    $Tween.start()

    if button_type == ButtonType.NONE:
        # dismiss the bubble after set time
        yield(get_tree().create_timer(wait_time), "timeout")
    else:
        # wait for a click
        yield(button, "pressed")
    
    $Tween.remove_all()
    $Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5)
    $Tween.start()
    
    is_speaking = false
    emotion = "no emotion "
    emit_signal("done_speaking")




