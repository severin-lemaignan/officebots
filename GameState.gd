extends Node

const MAX_SLOPE_ANGLE = deg2rad(30) # max angle that characters can climb

enum {CLIENT, SERVER, STANDALONE}

var mode = STANDALONE

func _ready():
    pass
