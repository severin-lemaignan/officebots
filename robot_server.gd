extends Node
class_name RobotServer

const ROBOT_SERVER_PORT=6970
var robot_server

var robots = {}

# name -> ID mapping
var names = {}

var game_instance

func _init(game_instance):
    
    self.game_instance = game_instance
    
    print("STARTING ROBOTS WEBSOCKET SERVER")
    robot_server = WebSocketServer.new

    # the last 'false' parameter disables the Godot high-level multiplayer API
    robot_server.listen(ROBOT_SERVER_PORT, PoolStringArray(), false)


    robot_server.connect("client_connected", self, "_robot_connected")
    robot_server.connect("client_disconnected", self, "_robot_disconnected")

    robot_server.connect("data_received", self, "_on_robot_data")

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
    var data = robot_server.get_peer(id).get_packet()
    
    
    var json = JSON.parse(data.get_string_from_utf8())
    if json.error != OK:
        print("Received invalid JSON command for the robot:")
        print(data.get_string_from_utf8())
        robot_server.get_peer(id).put_packet(("ERR Malformed JSON").to_utf8())
    
    var name = json.result[0]
    var robot = robots[names[name]]
    
    var cmd = json.result[1]
    var params = json.result[2]
    
    match cmd:
        "navigate-to":
            robot.set_navigation_target(convert_coordinates(params[0], params[1], params[2]))
            robot_server.get_peer(id).put_packet(("OK").to_utf8())
            return
        "set-color":
            robot.set_color()
            

    robot_server.get_peer(id).put_packet(("ERR Unknown command").to_utf8())
########################################################
