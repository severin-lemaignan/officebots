extends Node
class_name RobotServer

const ROBOT_SERVER_PORT=6970
var robot_server


var game_instance

func _init(game):
    
    self.game_instance = game
    
    print("STARTING ROBOTS WEBSOCKET SERVER")
    robot_server = WebSocketServer.new()

    # the last 'false' parameter disables the Godot high-level multiplayer API
    robot_server.listen(ROBOT_SERVER_PORT, PoolStringArray(), false)


    robot_server.connect("client_connected", self, "_robot_connected")
    robot_server.connect("client_disconnected", self, "_robot_disconnected")

    robot_server.connect("data_received", self, "_on_robot_data")

func poll():
    robot_server.poll()
    
##### NETWORK SIGNALS HANDLERS #####
    
func _robot_connected(id, protocol):
    # Called on both clients and server when a peer connects. Send my info to it.
    print("New robot " + str(id) + " joined (protocol: " + protocol + ")")
    
func _robot_disconnected(id, _was_clean_close):
    print("Robot " + str(id) + " disconnected")

func convert_coordinates_robotics2godot(x,y,z):
    # Takes coordinates in the usual robotics conventions, and convert them to Godot's convention
    # Robotics convention: z up
    # Godot convention: y up
    return Vector3(y,z,x)

func convert_coordinates_godot2robotics(vec3):
    # Takes coordinates in the usual robotics conventions, and convert them to Godot's convention
    # Robotics convention: z up
    # Godot convention: y up
    return Vector3(vec3.z,vec3.x,vec3.y)

func _on_robot_data(id):
    var data = robot_server.get_peer(id).get_packet()
    
    
    var json = JSON.parse(data.get_string_from_utf8())
    if json.error != OK:
        print("Received invalid JSON command for the robot:")
        print(data.get_string_from_utf8())
        send_error(id, "Malformed JSON")
    
    
    var name = json.result[0]
    var cmd = json.result[1]

    var params
    if json.result.size() == 3:
        params = json.result[2]
    
    if cmd == "create":
        game_instance.rpc("add_robot", name)
        send_ok(id)
        return
            
    var robot
    if name in game_instance.robots:
        robot = game_instance.robots[name]
    else:
        send_error(id, "Unknown robot: " + name + ". Use 'create' to first create a robot")
        return
        
    match cmd:
        "navigate-to":
            if params.size() != 0:
                send_error(id, "navigate-to takes exactly 2 parameters (destination's x and y)")
                return
                
            robot.set_navigation_target(convert_coordinates_robotics2godot(params[0], params[1], 0))
            send_ok(id)
            return
        "stop":
            if params.size() != 0:
                send_error(id, "stop does not take any parameter")
                return
                
            robot.stop_navigation()
            send_ok(id)
            return
        "get-pos":
            if params.size() != 0:
                send_error(id, "get-pos does not take any parameter")
                return
                
            var pos = convert_coordinates_godot2robotics(robot.global_transform.origin)
            send_ok(id, [pos.x, pos.y])
            return
        "set-color":
            if params.size() != 1:
                send_error(id, "set-color requires exactly one parameter (the color name)")
                return
            var color = params[0]
            if !(color in robot.textures):
                send_error(id, "unknown color: " + color)
                return
            robot.rpc("set_color", params[0])
            send_ok(id)
            return
        "get-humans":
            if params.size() != 0:
                send_error(id, "get-humans does not take any parameter")
                return
            
            var humans = game_instance.compute_visible_humans(robot)
            var res = []
            for h in humans:
                var pos = convert_coordinates_godot2robotics(h.global_transform.origin)
                res.append([h.username, pos.x, pos.y])

            send_ok(id, res)
            return

    send_error(id, "Unknown command: " + cmd)

func send_error(id, msg):
    robot_server.get_peer(id).put_packet(JSON.print(["EE",  msg]).to_utf8())

func send_ok(id, msg = null):
    robot_server.get_peer(id).put_packet(JSON.print(["OK", msg]).to_utf8())
    
    
########################################################
