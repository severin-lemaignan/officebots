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
    
remotesync func set_color(color):
    
    $robot/Robot.mesh = meshes[color]
    

remotesync func set_screen_texture(image_name):
    # TODO: cache image on the peers so that there is no need to re-upload them every time
    
    var jpg_buffer = game_instance.screen_textures[image_name]
    
    #tex.image.lock()
    #print(tex.image.get_pixel(320, 240))
    var mesh = $robot/Screen.mesh.duplicate()
    var material = $robot/Screen.mesh.surface_get_material(1).duplicate()

    material.albedo_texture.image.load_jpg_from_buffer(jpg_buffer)
    mesh.surface_set_material(1, material)
    
    $robot/Screen.mesh = mesh
    
# should only run on the server!
func _physics_process(_delta):
    assert(is_network_master())
    
    
    if path_node < path.size():
        var direction = (path[path_node] - global_transform.origin)
        if direction.length() < 0.2:
            path_node += 1
        else:
            var _vel = move_and_slide(direction.normalized() * speed, Vector3.UP)

    rpc_unreliable("set_puppet_transform", transform)
    
    

func set_navigation_target(target):
    print("Computing new navigation path for robot...")
    path = navigation.get_simple_path(global_transform.origin, target)
    path_node = 0
    
    if path.size() == 0:
        print("[!!] No path found to " + str(target))
        return [false, "No path found"]
        
    return [true,""]

func stop_navigation():
    path = []
    path_node = 0

