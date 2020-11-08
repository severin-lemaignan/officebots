extends Control

onready var chat = $Bottom/Chat

signal on_chat_msg
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    chat.connect("text_entered", self, "on_chat")


func on_chat(msg):
    emit_signal("on_chat_msg", msg)
    chat.text = ""
