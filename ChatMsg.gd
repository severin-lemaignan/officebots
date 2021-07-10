extends MarginContainer
class_name ChatMsg

var margin_value = 14
var own_msg_style = preload("ChatMsgOwn.tres")
var others_msg_style = preload("ChatMsg.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
    add_constant_override("margin_top", margin_value)
    add_constant_override("margin_left", margin_value)
    add_constant_override("margin_bottom", margin_value)
    add_constant_override("margin_right", margin_value)
    
func set_own_msg(own_msg):

    if own_msg:
        add_constant_override("margin_left", margin_value + 20)
        add_constant_override("margin_right", margin_value)
        $Container.set('custom_styles/panel', own_msg_style)
        
    else:
        add_constant_override("margin_left", margin_value)
        add_constant_override("margin_right", margin_value + 20)
        $Container.set('custom_styles/panel', others_msg_style)


func set_text(msg, author=null):
    if not author:
        $Container/VBoxContainer/Author.visible = false
    else:
        $Container/VBoxContainer/Author.bbcode_text = "[b][color=#347661]" + author + "[/color][/b]"
        $Container/VBoxContainer/Author.visible = true
        
    $Container/VBoxContainer/Text.text = msg
    
