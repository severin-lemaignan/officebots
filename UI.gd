extends Control

onready var portrait = $CharacterViewport/Character

var robot_online = preload("res://assets/icons/robot-online.svg")
var robot_online_hover = preload("res://assets/icons/robot-online.svg")
var robot_offline = preload("res://assets/icons/robot-sleepy.svg")
var robot_offline_hover = preload("res://assets/icons/robot-sleepy-hover.svg")
var robot_connecting = preload("res://assets/icons/robot-connecting.svg")
var robot_connecting_hover = preload("res://assets/icons/robot-connecting-hover.svg")


signal on_expression


# Called when the node enters the scene tree for the first time.
func _ready():
    
    var _err = $Top/HBoxContainer/settings.connect("pressed", self, "on_settings") 
    
    if GameState.robots_enabled():
        _err = $Top/HBoxContainer/robot.connect("pressed", self, "on_robot_clicked")    
        _err = GameState.connect("robot_state_changed", self, "on_robot_state_changed")
    else:
        $Top/HBoxContainer/robot.hide()
    
    _err = $Bottom/Actions/ExpressionGroup/happy.connect("pressed", self, "emit_signal", ["on_expression", GameState.Expressions.NEUTRAL])
    _err = $Bottom/Actions/ExpressionGroup/sad.connect("pressed", self, "emit_signal", ["on_expression", GameState.Expressions.SAD])
    _err = $Bottom/Actions/ExpressionGroup/angry.connect("pressed", self, "emit_signal", ["on_expression", GameState.Expressions.ANGRY])
    _err = $Bottom/Actions/ExpressionGroup/excited.connect("pressed", self, "emit_signal", ["on_expression", GameState.Expressions.HAPPY])
    
    connect("on_expression" ,portrait, "set_expression")
    
    portrait.portrait_mode(true)
    portrait.set_close_up_camera()

func set_name_skin(name, skin):
    $Top/HBoxContainer2/NameBox/Name.text = name
    portrait.set_base_skin(skin)
    
func on_settings():
    $Settings.show()

func toggle_robots_support(active):
    if active:
        $Top/HBoxContainer/robot.show()
    else:
        $Top/HBoxContainer/robot.hide()
        
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


func _process(_delta):
    var tex = $CharacterViewport.get_texture()
    $Top/HBoxContainer2/Portrait.texture = tex
