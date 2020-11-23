extends Node

const MAX_SLOPE_ANGLE = deg2rad(30) # max angle that characters can climb

enum {UNSET, CLIENT, SERVER, STANDALONE}

var mode = UNSET

func _ready():
    pass
