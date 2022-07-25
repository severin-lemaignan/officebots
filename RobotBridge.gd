extends KinematicBody
class_name Robot

#const SERVER_URL="research.skadge.org"
const SERVER_URL="localhost"
const SERVER_PORT=6970

var robot_name

# set by Game.gd upon instantion (cf Game.add_robot)
var game_instance

var navigation
var path = []
var path_node = 0
var speed = 1

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

onready var camera = $robot/Viewport/Camera

func _ready():
	
	camera.far = CAMERA_FAR
	
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
	
# should only run on the server!
func _physics_process(delta):
	
	assert(GameState.mode == GameState.SERVER || GameState.mode == GameState.STANDALONE)
	
	
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
	
	## ATTEMPTS TO CAPTURE THE ROBOT CAMERA
	## (currently returns an empty image, most likely because the frame is not yet drawn)
	## (would be good to try outside of pyhiscs process)
	#var tex = ImageTexture.new()
	#$robot/Viewport.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	## Wait until the frame has finished before getting the texture.
	#yield(VisualServer, "frame_post_draw")
	#var img = $robot/Viewport.get_texture().get_data()
	
	#img.save_png("/tmp/tex.png")
	#tex.create_from_image(img)
	
	#$robot/Screen.mesh.surface_get_material(1).albedo_texture = tex
		
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

func stop():
	
	linear_velocity = 0
	angular_velocity = 0
	
	path = []
	path_node = 0

