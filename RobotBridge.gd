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

var linear_velocity = null
var angular_velocity = null

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

onready var camera = $robot/Camera

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

func set_screen_texture(image_name):
    
    set_screen_texture_remote(image_name)
    
    # only in CLIENT/SERVER mode, no need in STANDALONE mode
    if GameState.mode == GameState.SERVER:
        rpc("set_screen_texture_remote", image_name)
        
puppet func set_screen_texture_remote(image_name):
    # TODO: cache image on the peers so that there is no need to re-upload them every time
    
    var jpg_buffer = game_instance.screen_textures[image_name]
    var img = Image.new()
    img.load_jpg_from_buffer(jpg_buffer)
    img.lock()
    
    var tex = ImageTexture.new()
    tex.create_from_image(img)
    
    #var mesh = $robot/Screen.mesh.duplicate()
    #var material = $robot/Screen.mesh.surface_get_material(1).duplicate()

    $robot/Screen.mesh.surface_get_material(1).albedo_texture = tex
    #material.albedo_texture.set_data(img)

    #mesh.surface_set_material(1, material)
    
    #$robot/Screen.mesh = mesh
    
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
        var _vel = move_and_slide(Vector3(linear_velocity,0,0), Vector3.UP)
        
    if GameState.mode == GameState.SERVER:
        rpc_unreliable("set_puppet_transform", transform)
    
    
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
    
    linear_velocity = null
    angular_velocity = null
    
    path = []
    path_node = 0

