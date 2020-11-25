extends Node
class_name RobotServer

const API_SERVER_PORT=6970

var connected:bool = false
var robot_server

var game_instance

# used to publish the state of the robot
var pub_timer = Timer.new()
var pub_interval = 0.1 #s

func _init(game):
    
    self.game_instance = game
    
    if GameState.mode == GameState.STANDALONE:
        print("STARTING ROBOTS WEBSOCKET CLIENT (STANDALONE mode). YOU NEED TO START THE PYTHON WEBSOCKET SERVER")
        robot_server = WebSocketClient.new()
        robot_server.connect("connection_error", self, "_on_connection_error")
        robot_server.connect("connection_established", self, "_on_connection_established")
        robot_server.connect("connection_closed", self, "_on_connection_closed")
        
        pub_timer.wait_time = pub_interval
        pub_timer.one_shot = false
        pub_timer.connect("timeout", self, "publish_robot_state")
        game_instance.add_child(pub_timer)
        
        self.attempt_connect_relay_server()
        
        robot_server.connect("data_received", self, "_on_robot_data")
    
    

func attempt_connect_relay_server():
    # the last 'false' parameter disables the Godot high-level multiplayer API
    var error = robot_server.connect_to_url("localhost:" + str(API_SERVER_PORT), PoolStringArray(), false)
    if error != OK:
        print("Error: " + str(error))
    
func poll():

    robot_server.poll()

func publish_robot_state():
    if connected and game_instance.local_robot:

        var state = get_state()
        robot_server.get_peer(1).put_packet(JSON.print([0, state]).to_utf8())


func get_state():
    var robot = game_instance.local_robot
    var pos = convert_coordinates_godot2robotics(robot.global_transform.origin)
    return [pos[0], pos[1]]
    
##### NETWORK SIGNALS HANDLERS #####

func _on_connection_error():
    assert(GameState.mode==GameState.STANDALONE)
    connected = false
    
    # wait 1/2 sec and try to reconnect
    yield(game_instance.get_tree().create_timer(.5), "timeout")
    print("Trying to reconnect to API server...")
    self.attempt_connect_relay_server()


func _on_connection_established(_protocol):
    assert(GameState.mode==GameState.STANDALONE)
    
    print("Connection established to the API server")
    connected = true
    pub_timer.start()

func _on_connection_closed(is_clean):
    connected = false
    print("Connection to the API server closed. Trying to reconnect...")
    self.attempt_connect_relay_server()

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

puppet func puppet_load_image(jpg_buffer):
#    var img = Image.new()
#
#    var err = img.load_jpg_from_buffer(jpg_buffer)
#
#    if !err == OK:
#        print("Error code " + str(err) + " while loading the jpg image")
#        return
#
#    print("Successfully loaded JPG image " + name + " of size " + str(img.get_size()))
#    game_instance.screen_textures[name] = ImageTexture.new()
#    game_instance.screen_textures[name].create_from_image(img)
    game_instance.screen_textures[name] = jpg_buffer
        
func _on_robot_data():
    var data = robot_server.get_peer(1).get_packet()
    process_incoming_data(data)
    
func process_incoming_data(data):
    var json = JSON.parse(data.get_string_from_utf8())
    if json.error != OK:
        print("Received invalid JSON command for the robot:")
        print(data.get_string_from_utf8())
        send_error(-1, "Malformed JSON")
    
    var id = json.result[0]
    
    var target = json.result[1][0]
    var cmd = json.result[1][1]

    var params
    if json.result[1].size() == 3:
        params = json.result[1][2]
    
    if target == "server": # special server commands
        match cmd:
            #server-api
            "load-jpg":
                #
                # uploads a named JPG image to the server, for future use (for 
                # instance, for use as a texture on a robot's screen)
                #
                # params:
                var name: String # the name of the image
                var image: String # a base64-encoded JPG image
                ####
                
                name = params[0]
                image = params[1]
                
                var jpg_buffer = Marshalls.base64_to_raw(image)
                
                # first, try loading the image on the server, to ensure the jpg
                # buffer is correct
                #var img = Image.new()
                
                #var err = img.load_jpg_from_buffer(jpg_buffer)
                
                #if !err == OK:
                #    send_error(id, "Error code " + str(err) + " while loading the jpg image")
                #    return
            
                #print("Successfully loaded JPG image " + name + " of size " + str(img.get_size()))
                #game_instance.screen_textures[name] = ImageTexture.new()
                #game_instance.screen_textures[name].create_from_image(img)
                game_instance.add_screen_texture(name, jpg_buffer)
                
                # then, load the image on all the pother peers
                

                send_ok(id)
                return
            
        send_error(id, "Unknown server command: " + cmd)
        return
    
    match cmd:
        #robot-api
        "create":
            #
            # instantiates a new robot in the game
            #
            # params:
            var name: String # the robot's name
            ####
            
            name = target
            game_instance.add_robot(name)
            send_ok(id)
            return
                
    var robot
    if target in game_instance.robots:
        robot = game_instance.robots[target]
    else:
        send_error(id, "Unknown robot: " + target + ". Use 'create' to first create a robot")
        return
        
    match cmd:
        #robot-api
        "navigate-to":
            #
            # plans a path to the given destination, and starts navigating to it.
            #
            # params:
            var x: float # destination's x coordinate, in the world frame
            var y: float # destination's y coordinate, in the world frame
            ####

            if params.size() != 0:
                send_error(id, "navigate-to takes exactly 2 parameters (destination's x and y)")
                return
            x = params[0]
            y = params[1]
            
            var res = robot.set_navigation_target(convert_coordinates_robotics2godot(x, y, 0))
            if res[0]:
                send_ok(id)
            else:
                send_error(id, res[1])
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
            robot.set_color(params[0])
            send_ok(id)
            return
        "set-screen":
            if params.size() != 1:
                send_error(id, "set-screen requires exactly one parameter (the name of the image)")
                return
            var img = params[0]
            if !(img in game_instance.screen_textures):
                send_error(id, "unknown image: " + img + " (images must first be uploaded with eg 'load-jpg')")
                return
            robot.set_screen_texture(img)
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
    robot_server.get_peer(1).put_packet(JSON.print([id,["EE",  msg]]).to_utf8())

func send_ok(id, msg = null):
    robot_server.get_peer(1).put_packet(JSON.print([id, ["OK", msg]]).to_utf8())
    
    
########################################################
