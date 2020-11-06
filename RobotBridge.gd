extends KinematicBody

#const SERVER_URL="research.skadge.org"
const SERVER_URL="localhost"
const SERVER_PORT=6970

var server

var navigation
var path = []
var path_node = 0
var speed = 1

func _ready():
    
    print("STARTING ROBOT BRIDGE SERVER")
    server = WebSocketServer.new()
    
    # the last 'false' parameter disables the Godot high-level multiplayer API
    server.listen(SERVER_PORT, PoolStringArray(), false)
    
    
    server.connect("client_connected", self, "_robot_connected")
    server.connect("client_disconnected", self, "_robot_disconnected")
    
    server.connect("data_received", self, "_on_robot_data")


func _physics_process(_delta):
    
    server.poll()
    
    if path_node < path.size():
        var direction = (path[path_node] - global_transform.origin)
        if direction.length() < 0.2:
            path_node += 1
        else:
            move_and_slide(direction.normalized() * speed, Vector3.UP)

func set_navigation_target(target):
    print("Computing new navigation path for robot...")
    path = navigation.get_simple_path(global_transform.origin, target)
    path_node = 0
    
    if path.size() == 0:
        print("[!!] No path found to " + str(target))

##### NETWORK SIGNALS HANDLERS #####
    
func _robot_connected(id, protocol):
    # Called on both clients and server when a peer connects. Send my info to it.
    print("New robot " + str(id) + " joined (protocol: " + protocol + ")")
    
func _robot_disconnected(id, was_clean_close):
    print("Robot " + str(id) + " disconnected")

func convert_coordinates(x,y,z):
    # Takes coordinates in the usual robotics conventions, and convert them to Godot's convention
    # Robotics convention: z up
    # Godot convention: y up
    return Vector3(y,z,x)
    
func _on_robot_data(id):
    var data = server.get_peer(id).get_packet()
    
    
    var json = JSON.parse(data.get_string_from_utf8())
    if json.error != OK:
        print("Received invalid JSON command for the robot:")
        print(data.get_string_from_utf8())
        server.get_peer(id).put_packet(("ERR Malformed JSON").to_utf8())
    
    var cmd = json.result[0]
    var params = json.result[1]
    
    if cmd == "navigate-to":
        set_navigation_target(convert_coordinates(params[0], params[1], params[2]))
        server.get_peer(id).put_packet(("OK").to_utf8())
        return
        

    server.get_peer(id).put_packet(("ERR Unknown command").to_utf8())
########################################################
