extends MarginContainer
class_name ChatMsg

var reaction_happy = preload("res://assets/icons/happy.svg")
var reaction_smily = preload("res://assets/icons/smily.svg")
var reaction_laughing = preload("res://assets/icons/laughing.svg")
var reaction_confused = preload("res://assets/icons/unknown.svg")
var reaction_bored = preload("res://assets/icons/tired.svg")


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
        $Container/VBoxContainer/Author.bbcode_text = "[b][color=#236550]" + author + "[/color][/b]"
        $Container/VBoxContainer/Author.visible = true
    
    
    if msg == ":happy:":
        $Container/VBoxContainer/Text.visible = false
        $Container/VBoxContainer/ReactionContainer.visible = true
        $Container/VBoxContainer/ReactionContainer/Reaction.texture = reaction_happy
    elif msg == ":smily:":
        $Container/VBoxContainer/Text.visible = false
        $Container/VBoxContainer/ReactionContainer.visible = true
        $Container/VBoxContainer/ReactionContainer/Reaction.texture = reaction_smily
    elif msg == ":laughing:":
        $Container/VBoxContainer/Text.visible = false
        $Container/VBoxContainer/ReactionContainer.visible = true
        $Container/VBoxContainer/ReactionContainer/Reaction.texture = reaction_laughing
    elif msg == ":confused:":
        $Container/VBoxContainer/Text.visible = false
        $Container/VBoxContainer/ReactionContainer.visible = true
        $Container/VBoxContainer/ReactionContainer/Reaction.texture = reaction_confused
    elif msg == ":bored:":
        $Container/VBoxContainer/Text.visible = false
        $Container/VBoxContainer/ReactionContainer.visible = true
        $Container/VBoxContainer/ReactionContainer/Reaction.texture = reaction_bored
    else:
        $Container/VBoxContainer/Text.text = msg
        $Container/VBoxContainer/Text.visible = true
        $Container/VBoxContainer/ReactionContainer.visible = false
    
