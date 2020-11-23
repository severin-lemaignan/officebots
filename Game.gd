extends Spatial

# set the initial game mode. Can be overridden by 
# command-line arguments --server, --client, --standalone

enum modes {CLIENT, SERVER, STANDALONE}

export(modes) var run_as = GameState.STANDALONE

var SERVER_URL="localhost"
const SERVER_PORT=6969


var is_networking_started

var local_player
var player_name
var player_skin

# dictionary of ImageTexture created by users of the Python API when
# uploading images to the server.
# used eg to set the texture on the robots' screens
var screen_textures = {}

# if changing that, make sure to add spawn points accordingly
var MAX_PLAYERS = 10

export(String) var username = "John Doe"

# Player info, associate ID to data
var player_info = {}

var robots = {}

var robot_server


func _ready():
    
    randomize()
    
    GameState.mode = run_as
    
    for argument in OS.get_cmdline_args():
        if argument == "--server":
            GameState.mode = GameState.SERVER
        if argument == "--client":
            GameState.mode = GameState.CLIENT
        if argument == "--standalone":
            GameState.mode = GameState.STANDALONE
    
    # the web version are always clients;
    if OS.get_name() == "HTML5" and GameState.mode == GameState.SERVER:
        print("ERROR: when exporting to HTML5 platform, the game can *not* be in server mode")
        get_tree().quit(1)
    
    if GameState.mode == GameState.CLIENT:

        $FakePlayer/Camera.current = false
        
        if OS.get_name() == "HTML5":
            var SERVER_URL="research.skadge.org"
            print("Setting the game server to " + SERVER_URL + ":" + SERVER_PORT)
    
    elif GameState.mode == GameState.SERVER:

        $FakePlayer/Camera.current = true
        $CanvasLayer/UI.visible = false
        $CanvasLayer/CharacterSelection.visible = false
    
    elif GameState.mode == GameState.STANDALONE:
        
        $FakePlayer/Camera.current = false
        
    else:
        assert(false)
        
    var peer

    # Flow chart when joining:
    # 1. Peer connects to the server -> _connect_ok -> pre_configure_game
    # 2. pre_configure_game creates the local 'Player' node and calls done_preconfiguring(peer_id) on the server
    # 3. the server stores details about this new peer and calls back the peer with 'post_configure_game(start_location)'
    # 4. post_configure_game simply 'un-pause' the game
    #
    # *Simultaneously*:
    # 1. All the existing peers (including the server) receive an event 'network_peer_connected(peer_id)'
    # 1bis. the peer receives as well an event 'network_peer_connected(1)' from the server
    # 2. in _player_connected, each peer send to the new peer its details via 'register_player'
    # 2bis. the new peer sends its details to the server, for the server to create the character as well
    # 3. register_player -> add_player that creates Character node instance for each other peers on the new peer
    
    # called when a player joins the game
    var _err = get_tree().connect("network_peer_connected", self, "_player_connected")
    
    # called when a player leaves the game
    _err = get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
    

    # called when *I* connect to the server
    _err = get_tree().connect("connected_to_server", self, "_connected_ok")
    _err = get_tree().connect("connection_failed", self, "_connected_fail")
    # called when the server disconnect, eg is killed
    _err = get_tree().connect("server_disconnected", self, "_server_disconnected")
    
            
    if GameState.mode == GameState.SERVER:
        print("STARTING AS SERVER")
        
        peer = WebSocketServer.new()

        # the last 'true' parameter enables the Godot high-level multiplayer API
        var error = peer.listen(SERVER_PORT, PoolStringArray(), true)
        
        if error != OK:
            match error:
                ERR_ALREADY_IN_USE:
                    print("Port already in use! Most likely a server is already running. Exiting.")
                    get_tree().quit(1)
                    return
                _:
                    print("Error code " + str(error) + " when starting the server. Exiting.")
                    get_tree().quit(1)
                    return
                    
        get_tree().network_peer = peer
        is_networking_started = true        
        
        
        local_player = $FakePlayer
        configure_physics()
        
        robot_server = RobotServer.new(self)

        
    elif GameState.mode == GameState.CLIENT:
        print("STARTING AS CLIENT")
        
        set_physics_process(false)
    
        # wait for the character creation to be complete
        var res = yield($CanvasLayer/CharacterSelection,"on_character_created")
        player_name = res[0]
        player_skin = res[1]
        
        $CanvasLayer/UI.set_name_skin(player_name, player_skin)
        
        Input.set_default_cursor_shape(Input.CURSOR_DRAG)
        
        # then, initiate the connection to the server
        
        peer = WebSocketClient.new()
        
        # the last 'true' parameter enables the Godot high-level multiplayer API
        peer.connect_to_url(SERVER_URL + ":" + str(SERVER_PORT), PoolStringArray(), true)
        get_tree().network_peer = peer
        
        is_networking_started = true

    elif GameState.mode == GameState.STANDALONE:
        print("STARTING IN STANDALONE MODE")

        # wait for the character creation to be complete
        var res = yield($CanvasLayer/CharacterSelection,"on_character_created")
        player_name = res[0]
        player_skin = res[1]
        
        $CanvasLayer/UI.set_name_skin(player_name, player_skin)
        
        Input.set_default_cursor_shape(Input.CURSOR_DRAG)
        
        configure_physics()
        robot_server = RobotServer.new(self)
        
        
        


func configure_physics():
    shuffle_spawn_points()
    
    # enable physics calculations for all the dynamics objects, *on the server only*
    for o in $MainOffice/DynamicObstacles.get_children():
        o.call_deferred("set_physics_process", true)
    
func _process(_delta):
    
    if is_networking_started:
        # server & clients need to poll, according to https://docs.godotengine.org/en/stable/classes/class_websocketclient.html#description
        get_tree().network_peer.poll()
        
        # only the server polls for the robot websocket server
        if is_network_master():
            robot_server.poll()

# should only run on the server!
func _physics_process(_delta):
    
    assert(GameState.mode == GameState.SERVER || GameState.mode == GameState.STANDALONE)
    if GameState.mode == GameState.SERVER:
        assert(is_network_master())
    
        # check visibility of players:
    # 1. select robot's camera
    # 2. quick discard using a VisbilityNotifier https://docs.godotengine.org/en/stable/classes/class_visibilitynotifier.html
    # 3. ray casting from robot to player to see if obstacle or not, using
    #    intersect_ray: https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html
    

func compute_visible_humans(robot):

    for p in $Players.get_children():
        if p in robot.players_in_fov:
            var ob = is_object_visible(p.face, robot.camera)
            if !ob or !ob.has_method("i_am_a_character"):
                robot.players_in_fov.erase(p)
        else:
            var ob = is_object_visible(p.face, robot.camera)
            if ob and ob.has_method("i_am_a_character"):
                robot.players_in_fov.append(ob)
                print("Robot " + robot.robot_name + " sees player " + p.username)
    
    return robot.players_in_fov
                        
func is_object_visible(object, camera):
    var target = object.global_transform.origin
    if is_point_in_frustum(target, camera):
        var space_state = get_world().direct_space_state
        var result = space_state.intersect_ray(camera.global_transform.origin, target)
        if result:
            return result.collider

    return null

func is_point_in_frustum(point, camera):
    var f = camera.get_frustum()
    
    return(!(f[0].is_point_over(point) or \
             f[1].is_point_over(point) or \
             f[2].is_point_over(point) or \
             f[3].is_point_over(point) or \
             f[4].is_point_over(point) or \
             f[5].is_point_over(point)))
    


func shuffle_spawn_points():
    var order = range($SpawnPointsPlayers.get_child_count())

    order.shuffle()
    for p in range(order.size()):
        var child = $SpawnPointsPlayers.get_child(order[p])
        $SpawnPointsPlayers.move_child(child, p)
    
    order = range($SpawnPointsRobots.get_child_count())
    order.shuffle()
    for p in range(order.size()):
        var child = $SpawnPointsRobots.get_child(order[p])
        $SpawnPointsRobots.move_child(child, p)

##### NETWORK SIGNALS HANDLERS #####
# only triggered client-side
func _connected_ok():
    print("Yeah! Connected to the server")
    pre_configure_game()

# only triggered client-side
func _connected_fail():
    print("Impossible to connect :-(  Server dead?")

# only triggered client-side
func _server_disconnected():
    print("Server disconnect")
    
func _player_connected(id):
    # Called on both clients and server when a peer connects. Send my info to it.
    
    #if not get_tree().is_network_server():
    #    rpc_id(id, "pre_register_player")
        
    
    var my_info =  { "name": player_name, "skin": player_skin }
    
    if id == 1:
        print("Sending my player to the server")
    else:
        print("New player " + str(id) + " joined")
        
    if not get_tree().is_network_server():
        rpc_id(id, "register_player", my_info)
    
func _player_disconnected(id):
    print("Player " + str(id) + " disconnected")
    remove_player(id)
    player_info.erase(id) # Erase player from info.

########################################################

# excuted on every existing peer (incl server) when a new player joins
#remote func pre_register_player():
#    # Get the id of the RPC sender.
#    var id = get_tree().get_rpc_sender_id()
#    # Store the info
#    player_info[id] = {}
#
#    if get_tree().is_network_server():
#        print("New player connected -- pre-registering id: " + str(id))

# excuted on every existing peer (incl server) when a new player joins
remote func register_player(info):
    
    var id = get_tree().get_rpc_sender_id()
    
    player_info[id] = info
    
    add_player(id)
    
    if get_tree().is_network_server():
        print("Player " + player_info[id]["name"] + " (peer id #" + str(id) + "): registration & initialization complete")

func remove_player(id):
    player_info[id]["object"].queue_free()
    
func add_player(id):
    print("Creating character instance for peer #" + str(id))
    var player = preload("res://Character.tscn").instance()
    
    # this is key: by re-using the id, each player (be it a Player instance or 
    # a Character instance) will have the *same* node path on every peers, enabling
    # RPC calls
    
    player.set_name(str(id))
    
    # the server is ultimately controlling all the characters position
    # -> the network master is 1 (eg, default)
    #player.set_network_master(1)
    
    
    
    # physics *only* performed on server
    if get_tree().is_network_server():
        player.call_deferred("enable_collisions", true)
        player.call_deferred("set_physics_process", true)
        
        var start_location = $SpawnPointsPlayers.get_child($Players.get_child_count()).transform
        player_info[id]["start_location"] = start_location
        
        player.call_deferred("set_global_transform", start_location)        

        
    else:
        player.enable_collisions(false)
    
    
    player.set_deferred("local_player", local_player)
    player.call_deferred("set_username", player_info[id]["name"])
    player.call_deferred("set_base_skin", player_info[id]["skin"])
    
    
    
    get_node("/root/Game/Players").add_child(player)
    
    player_info[id]["object"] = player
    

remotesync func add_robot(name):
    print("Adding robot " + str(name))
    var robot = preload("res://RobotBridge.tscn").instance()
    
    robots[name] = robot
    
    robot.set_name(name)
    robot.set_deferred("robot_name", name)
    robot.set_deferred("game_instance", self)
    
    # physics *only* performed on server
    if get_tree().is_network_server():
        robot.enable_collisions(true)
        robot.call_deferred("set_physics_process", true)
        
        
    else:
        robot.enable_collisions(false)
    
    if is_network_master():
        
        var start_location = $SpawnPointsRobots.get_child($Robots.get_child_count()).transform
        robot.set_global_transform(start_location)
        
        robot.set_deferred("navigation", $MainOffice.nav)
    
    $Robots.add_child(robot)

remotesync func set_screen_texture(name, jpg_buffer):
    screen_textures[name] = jpg_buffer
    
func add_screen_texture(name, jpg_buffer):
    rpc("set_screen_texture", name, jpg_buffer)

remote func pre_configure_game():
    var selfPeerID = get_tree().get_network_unique_id()
        
    get_tree().set_pause(true)

    
    # Load my player
    local_player = preload("res://Player.tscn").instance()
    local_player.set_name(str(selfPeerID))
    
    #local_player.set_network_master(selfPeerID)
    
    # the server is ultimately controlling the player position
    # -> the network master is 1 (eg, default)
    
    get_node("/root/Game/Players").add_child(local_player)
    
    var _err = $CanvasLayer/UI.connect("on_chat_msg", local_player, "say")
    $MainOffice.set_local_player(local_player)

    # Tell server (remember, server is always ID=1) that this peer is done pre-configuring.
    rpc_id(1, "done_preconfiguring", selfPeerID)
    
    print("Done pre-configuring game. Waiting for the server to un-pause me...")

# server has accepted our player, we can start the game.
# *if transform=null, the server has rejected our player*
# (typically because no more space). In which case, we must exit.
remote func post_configure_game(transform):
    if !transform:
        print("Server is full! Exiting")
        get_tree().quit()
    else:
        print("Starting the game!")
        local_player.transform = transform
        get_tree().set_pause(false)



# Executed on the server only
var players_done = []
remote func done_preconfiguring(who):
    # Here are some checks you can do, for example
    assert(get_tree().is_network_server())
    assert(who in player_info) # Exists
    assert(not who in players_done) # Was not added yet

    if players_done.size() == MAX_PLAYERS:
        print("Game full! Can not accept any extra player!")
        rpc_id(who, "post_configure_game", null)
        return
        
    print("Player #" + str(who) + " is ready.")
    players_done.append(who)

    # start the game immediately for whoever is connecting, passing the
    # start location of the player
    
    rpc_id(who, "post_configure_game", player_info[who]["start_location"])

