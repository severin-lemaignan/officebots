extends Node

const MAX_SLOPE_ANGLE = deg2rad(30) # max angle that characters can climb

enum {UNSET, CLIENT, SERVER, STANDALONE}

var mode = UNSET

enum RobotState {DISCONNECTED, CONNECTING, CONNECTED}
signal robot_state_changed
var robot_state = RobotState.DISCONNECTED

enum Expressions {NEUTRAL, ANGRY, HAPPY, SAD}

func _ready():
    var _err = connect("robot_state_changed", self, "on_robot_state_changed")

func on_robot_state_changed(state):
    robot_state = state

func convert_coordinates_robotics2godot(x,y,z):
    # Takes coordinates in the usual robotics conventions, and convert them to Godot's convention
    # Robotics convention: z up
    # Godot convention: y up
    return Vector3(y,z,x)

func convert_coordinates_godot2robotics(vec3):
    # Takes coordinates in the usual robotics conventions, and convert them to Godot's convention
    # Robotics convention: z up
    # Godot convention: y up
    return Vector3(vec3.z,vec3.x,vec3.y)
