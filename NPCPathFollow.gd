extends PathFollow3D

@export var skin: Texture2D
@export var npc_name: String = "Mysterious person"

var SPEED = 5 / 3.6 # in m/s

var next_pause = randf()
var PAUSE_LENGTH=2 #sec

var current_pause = -1
@onready var npc = $Character

func _ready():
	npc.set_skin(skin)
	npc.username = npc_name

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	if current_pause > 0:
		current_pause -= delta
	else:
		progress += SPEED * delta
	
	if current_pause < 0 and abs(next_pause - progress_ratio) < 0.001:
		next_pause = randf()
		current_pause = PAUSE_LENGTH
	
	if progress_ratio >= 1:
		progress_ratio = 0
