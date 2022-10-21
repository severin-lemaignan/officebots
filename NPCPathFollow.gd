extends PathFollow

export(Texture) var skin
export(String) var npc_name = "Mysterious person"

var SPEED = 5 / 3.6 # in m/s

var next_pause = randf()
var PAUSE_LENGTH=2 #sec

var current_pause = -1
onready var npc = $Character

func _ready():
	npc.set_skin(skin)
	npc.username = npc_name

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	if current_pause > 0:
		current_pause -= delta
	else:
		offset += SPEED * delta
	
	if current_pause < 0 and abs(next_pause - unit_offset) < 0.001:
		next_pause = randf()
		current_pause = PAUSE_LENGTH
	
	if unit_offset >= 1:
		unit_offset = 0
