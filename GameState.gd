extends Node

const MAX_SLOPE_ANGLE = deg2rad(30) # max angle that characters can climb

enum {UNSET, CLIENT, SERVER, STANDALONE}

var mode = UNSET

enum RobotState {DISCONNECTED, CONNECTING, CONNECTED}
signal robot_state_changed
var robot_state = RobotState.DISCONNECTED


func _ready():
    var _err = connect("robot_state_changed", self, "on_robot_state_changed")

func on_robot_state_changed(state):
    robot_state = state
