extends KinematicBody
class_name Robot

#const SERVER_URL="research.skadge.org"
const SERVER_URL="localhost"
const SERVER_PORT=6970

var server

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

func _ready():
    set_color("white")
    
    #set_screen_texture("res://assets/screen_tex_hello.png")
    
    # disable physics by default (will be only enabled on the server)
    set_physics_process(false)

   
func enable_collisions(val=true):
    $CollisionShape.disabled = !val

puppet func set_puppet_transform(transform):
    self.transform = transform
    
remotesync func set_color(color):
    
    var material = $robot/Robot.mesh.surface_get_material(0)
    material.albedo_texture = textures[color]

remotesync func set_screen_texture(resource_path):
    var material = $robot/Screen.mesh.surface_get_material(1)
    material.albedo_texture = load(resource_path)
    
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

func stop_navigation():
    path = []
    path_node = 0

