extends Control

onready var portrait = $CharacterViewport/Character

onready var chat = $Bottom/Chat

var robot_online = preload("res://assets/icons/robot-online.svg")
var robot_online_hover = preload("res://assets/icons/robot-online.svg")
var robot_offline = preload("res://assets/icons/robot-sleepy.svg")
var robot_offline_hover = preload("res://assets/icons/robot-sleepy-hover.svg")
var robot_connecting = preload("res://assets/icons/robot-connecting.svg")
var robot_connecting_hover = preload("res://assets/icons/robot-connecting-hover.svg")


signal on_chat_msg


# Called when the node enters the scene tree for the first time.
func _ready():
    chat.connect("text_entered", self, "on_chat")
    
    var _err = $Top/HBoxContainer/settings.connect("pressed", self, "on_settings")    
    _err = $Top/HBoxContainer/robot.connect("pressed", self, "on_robot_clicked")
    
    _err = GameState.connect("robot_state_changed", self, "on_robot_state_changed")
    
    portrait.portrait_mode(true)

func set_name_skin(name, skin):
    $Top/HBoxContainer2/NameBox/Name.text = name
    portrait.set_base_skin(skin)
    
func on_settings():
    $Settings.show()

func on_robot_clicked():
    
    # if we were DISCONNECTED, try to connect...
    if GameState.robot_state == GameState.RobotState.DISCONNECTED:
        GameState.emit_signal("robot_state_changed", GameState.RobotState.CONNECTING)
        return
        
    # ...if we were trying to connect, disconnect
    if GameState.robot_state == GameState.RobotState.CONNECTING:
        GameState.emit_signal("robot_state_changed", GameState.RobotState.DISCONNECTED)
        return

func on_robot_state_changed(state):
    
    match state:
        GameState.RobotState.DISCONNECTED:
            $Top/HBoxContainer/robot.texture_normal = robot_offline
            $Top/HBoxContainer/robot.texture_hover = robot_offline_hover
        GameState.RobotState.CONNECTED:
            $Top/HBoxContainer/robot.texture_normal = robot_online
            $Top/HBoxContainer/robot.texture_hover = robot_online_hover
        GameState.RobotState.CONNECTING:
            $Top/HBoxContainer/robot.texture_normal = robot_connecting
            $Top/HBoxContainer/robot.texture_hover = robot_connecting_hover

        
func on_chat(msg):
    emit_signal("on_chat_msg", msg)
    chat.text = ""

func _process(_delta):
    var tex = $CharacterViewport.get_texture()
    $Top/HBoxContainer2/Portrait.texture = tex
