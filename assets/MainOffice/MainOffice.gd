extends Spatial

onready var nav = $Navigation


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

# called by Game.gd upon player creation
func set_local_player(object):
    
    for d in $Doors.get_children():
        d.local_player = object

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
