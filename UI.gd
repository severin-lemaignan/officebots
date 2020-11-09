extends Control

onready var portrait = $CharacterViewport/Character

onready var chat = $Bottom/Chat

signal on_chat_msg
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    chat.connect("text_entered", self, "on_chat")
    
    $Top/HBoxContainer/exit.connect("pressed", self, "on_exit")
    
    portrait.portrait_mode(true)

func set_name_skin(name, skin):
    $Top/HBoxContainer2/NameBox/Name.text = name
    portrait.set_base_skin(skin)
    
func on_exit():
    $ModalMessage.show()
    var output = yield($ModalMessage, "on_choice")
    
    if output == "ok":
        get_tree().quit()

func on_chat(msg):
    emit_signal("on_chat_msg", msg)
    chat.text = ""

func _process(_delta):
    var tex = $CharacterViewport.get_texture()
    $Top/HBoxContainer2/Portrait.texture = tex
