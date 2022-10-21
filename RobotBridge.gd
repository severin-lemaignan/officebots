extends KinematicBody
class_name Robot

#const SERVER_URL="research.skadge.org"
const SERVER_URL="localhost"
const SERVER_PORT=6970

# to change the robot model, change the `model` variable + *adjust the scene!* (ie, import that right .glb file, adjust the position of the camera, etc)
enum {GENERIC, ARI}
var model = ARI

var robot_name
var username #alias for robot_name

# set by Game.gd upon instantion (cf Game.add_robot)
var game_instance

var navigation
var path = []
var path_node = 0
var speed = 1

var last_msg = []

var linear_velocity = 0
var angular_velocity = 0

var laser_ranges = []

var textures = {"black": load("res://assets/palette_texture_black.png"),
				"blue": load("res://assets/palette_texture_blue.png"),
				"yellow": load("res://assets/palette_texture_yellow.png"),
				"green": load("res://assets/palette_texture_green.png"),
				"red": load("res://assets/palette_texture_red.png"),
				"white": load("res://assets/palette_texture_white.png"),
				"purple": load("res://assets/palette_texture_purple.png"),
				"beige": load("res://assets/palette_texture_salmon.png")
			   }

var meshes = {}

var players_in_fov = []

# maximum distance for objects to be seen by the robot's camera
# nothing beyond that distance is visible, whatever its size
const CAMERA_FAR = 30

var local_player

onready var camera = $robot/Camera
onready var speech_bubble = $SpeechBubbleHandle/SpeechBubble
onready var speech_bubble_handle = $SpeechBubbleHandle

# emitted when this robot says something within Player's range
signal robot_msg

func _ready():
	
	camera.far = CAMERA_FAR
	
	if model == GENERIC:
		# prepare materials for the different robot colors
		for c in textures:
			
			meshes[c] = $robot/Robot.mesh.duplicate()
			var mat = meshes[c].surface_get_material(0).duplicate()
			mat.albedo_texture = textures[c]
			meshes[c].surface_set_material(0, mat)
		
		set_color("white")
	
	#set_screen_texture("res://assets/screen_tex_hello.png")
	
	# disable physics by default (will be only enabled on the server)
	set_physics_process(false)
	
	
func enable_collisions(val=true):
	$CollisionShape.disabled = !val

puppet func set_puppet_transform(transform):
	self.transform = transform
	
func set_color(color):
	
	if model != GENERIC:
		return
		
	set_color_remote(color)
	
	# only in CLIENT/SERVER mode, no need in STANDALONE mode
	if GameState.mode == GameState.SERVER:
		rpc("set_color_remote", color)

puppet func set_color_remote(color):
	
	$robot/Robot.mesh = meshes[color]

func set_screen_texture(jpg_buffer):
	
	var err = set_screen_texture_remote(jpg_buffer)
	
	# only in CLIENT/SERVER mode, no need in STANDALONE mode
	if GameState.mode == GameState.SERVER:
		rpc("set_screen_texture_remote", jpg_buffer)
	
	return err
		
puppet func set_screen_texture_remote(jpg_buffer):

	var img = Image.new()
	var err = img.load_jpg_from_buffer(jpg_buffer)
	img.lock()
	
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	
	$robot/Screen.mesh.surface_get_material(1).albedo_texture = tex
	
	return err

func distance_to(object):
	return get_global_transform().origin.distance_to(object.get_global_transform().origin)

# should only run on the server!
func _physics_process(delta):
	
	assert(GameState.mode == GameState.SERVER || GameState.mode == GameState.STANDALONE)
	
	# manage speech bubble, incl updating scale and orientation based on
	# player distance
	if not local_player:
		local_player = get_node("/root/Game/Players/myself")
		
	var dist = distance_to(local_player)
	$SpeechBubbleAnchorAxis.rotation.y = -rotation.y + local_player.camera.get_global_transform().basis.get_euler().y
			
	if speech_bubble.is_speaking:

		var screenPos = local_player.camera.unproject_position($SpeechBubbleAnchorAxis/SpeechBubbleAnchor.get_global_transform().origin)
		speech_bubble_handle.position = screenPos

		# Scale the speech bubble based on distance to player
		var bubble_scale = max(0.5, min(2, 1 / dist))
		speech_bubble_handle.scale = Vector2(bubble_scale, bubble_scale)
		
	if path_node < path.size():
		var direction = (path[path_node] - global_transform.origin)
		if direction.length() < 0.2:
			path_node += 1
		else:
			var _vel = move_and_slide(direction.normalized() * speed, Vector3.UP)

	elif (linear_velocity or angular_velocity):
		rotate_y(angular_velocity * delta)
		
		# TODO: map back the resulting vel to local coordinates, and send it back to 
		# client
		var _vel = move_and_slide(global_transform.basis.xform(Vector3(0,0,linear_velocity)), Vector3.UP)
		
	if GameState.mode == GameState.SERVER:
		rpc_unreliable("set_puppet_transform", transform)
	
	laser_ranges = $LaserScanner.laser_scan()

func say(text):
	
	#if local_player.is_in_range(self):
	speech_bubble.say(text, speech_bubble.ButtonType.NONE)
	
	# connected to the Chat interface in Game.gd
	emit_signal("robot_msg", text, username, false)
		
func typing():
	speech_bubble.typing()
	
func not_typing_anymore():
	speech_bubble.hide()
	
func set_v_w(v, w):
	linear_velocity = v
	angular_velocity = w
	
	return [true, ""]
	
func set_navigation_target(target):
	print("Computing new navigation path for robot...")
	path = navigation.get_simple_path(global_transform.origin, target)
	path_node = 0
	
	if path.size() == 0:
		print("[!!] No path found to " + str(target))
		return [false, "No path found"]
		
	return [true,""]

func heard(msg, user):
	last_msg = [msg, user]

func pop_last_msg():
	if not last_msg:
		return []
		
	var msg = last_msg[0]
	var user = last_msg[1]
	last_msg = []
	
	return [msg, user]

func stop():
	
	linear_velocity = 0
	angular_velocity = 0
	
	path = []
	path_node = 0

