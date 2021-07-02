extends Spatial

####### THESE ENUMS ARE *ONLY* FOR CONFIGURATION IN THE GODOT EDITOR UI ########
####### See GameState for the actual global variables used in the code #########

# set the initial game mode. Can be overridden by 
# command-line arguments --server, --client, --standalone
enum modes {UNSET, CLIENT, SERVER, STANDALONE}
export(modes) var run_as = modes.UNSET

# by default, the game supports adding robots; robots can be disabled if eg
# it is only played online with human users.
enum RobotsMode {ROBOTS, NO_ROBOTS}
export(RobotsMode) var has_robots = RobotsMode.ROBOTS

###############################################################################

var SERVER_URL="127.0.0.1"

var SERVER_PORT=6969

var time_start=0 
var time_now=0
var total_time = 600 #total time of the game in seconds


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
var local_robot = null

# whether or not laserscans are displayed. Changed via the settings in the UI
# (cf callback 'toggle_robots_lasers')
var show_laserscans = false

var robot_server

onready var navmesh = $MainOffice.get_navmesh()

func _ready():
    
    
    time_start= OS.get_unix_time()
        
    
    randomize()
    
    $CanvasLayer/GameModeSelection.visible = false
    var _err = $CanvasLayer/UI/Settings.connect("on_toggle_laser", self, "toggle_robots_lasers")
    
    set_physics_process(false)
    
    # highest priority for cmd line arguments.
    # -> they override any other parameter
    for argument in OS.get_cmdline_args():
        if argument == "--server":
            GameState.mode = GameState.SERVER
        if argument == "--client":
            GameState.mode = GameState.CLIENT
        if argument == "--standalone":
            GameState.mode = GameState.STANDALONE
        if "--name=" in argument:
            player_name = argument.right(7)
            player_skin = "res://assets/characters/skins/casualFemaleA_neutral.png"
        if "--server=" in argument:
            SERVER_URL = argument.right(9)
            
        if "--port=" in argument:
            SERVER_PORT = argument.right(7).to_int()
            
    # then, if game mode has been set in Godot, use that:
    if GameState.mode == GameState.UNSET:
        GameState.mode = run_as
        
    # finally, if still not set, show the selection screen
    if GameState.mode == GameState.UNSET:
        $CanvasLayer/GameModeSelection.visible = true
        var url = yield($CanvasLayer/GameModeSelection,"on_mode_set")

        if url == null: # single player!
            GameState.mode = GameState.STANDALONE
        else:
            GameState.mode = GameState.CLIENT
            SERVER_URL=url
            print("Setting the game server to " + SERVER_URL + ":" + str(SERVER_PORT))
    
    # at that point, we should know our game mode
    assert(GameState.mode != GameState.UNSET)
    
    # do we support robots or not?
    GameState.robots_mode = has_robots
    if GameState.robots_enabled():
        $CanvasLayer/UI.toggle_robots_support(true)
    else:
        $CanvasLayer/UI.toggle_robots_support(false)
        print("INFO: Robot support disabled.")
    
    set_physics_process(true)
        
    # the web version are always clients;
    if OS.get_name() == "HTML5" and GameState.mode == GameState.SERVER:
        print("ERROR: when exporting to HTML5 platform, the game can *not* be in server mode")
        get_tree().quit(1)
    
    if GameState.mode == GameState.CLIENT:

        $FakePlayer/Camera.current = false
        
        # the name of the player was given on cmd-line? no need to choose the dialog
        if player_name:
            $CanvasLayer/CharacterSelection.visible = false
    
    elif GameState.mode == GameState.SERVER:

        $FakePlayer/Camera.current = true
        $CanvasLayer/UI.visible = false
        $CanvasLayer/CharacterSelection.visible = false
    
    elif GameState.mode == GameState.STANDALONE:
        
        $FakePlayer/Camera.current = false
        
        # the name of the player was given on cmd-line? no need to choose the dialog
        if player_name:
            $CanvasLayer/CharacterSelection.visible = false
        
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
    _err = get_tree().connect("network_peer_connected", self, "_player_connected")
    
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
        
        if GameState.robots_enabled():
            robot_server = RobotServer.new(self)

        
    elif GameState.mode == GameState.CLIENT:
        print("STARTING AS CLIENT")
        
        set_physics_process(false)
    
        # if we do not already have the player name, wait for the character creation to be complete
        if not player_name:
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

        # if we do not already have the player name, wait for the character creation to be complete
        if not player_name:
            var res = yield($CanvasLayer/CharacterSelection,"on_character_created")
            player_name = res[0]
            player_skin = res[1]
        
        $CanvasLayer/UI.set_name_skin(player_name, player_skin)
        
        Input.set_default_cursor_shape(Input.CURSOR_DRAG)
        
        configure_physics()
        
        if GameState.robots_enabled():
            robot_server = RobotServer.new(self)
            
        is_networking_started = true   
        
        pre_configure_game()
        

func configure_physics():
    shuffle_spawn_points()
    #shuffle_missions()
    # enable physics calculations for all the dynamics objects, *on the server only* (or in stand-alone mode)
    for o in $MainOffice/DynamicObstacles.get_children():
        o.call_deferred("set_physics_process", true)
    for o in $MainOffice/PickableObjects.get_children():
        o.call_deferred("set_physics_process", true)
    
    
func _process(_delta):
    
    show_time()
        
    if is_networking_started:
        
        
        if GameState.mode == GameState.SERVER or GameState.mode == GameState.CLIENT:
            # server & clients need to poll, according to https://docs.godotengine.org/en/stable/classes/class_websocketclient.html#description
            get_tree().network_peer.poll()
        
        if GameState.robots_enabled():
            # only the server polls for the robot websocket server (or the standalone client)
            if GameState.mode == GameState.SERVER or GameState.mode == GameState.STANDALONE:
                robot_server.poll()

# should only run on the server!
func _physics_process(_delta):
    
    assert(GameState.mode == GameState.SERVER || GameState.mode == GameState.STANDALONE)
    if GameState.mode == GameState.SERVER:
        assert(is_network_master())
        are_missions_done()
        
        
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

    var my_info =  { "name": player_name, "skin": player_skin }
    
    if id == 1:
        print("Sending my player to the server")
    else:
        print("New player " + str(id) + " joined")
        create_file(str(id))
        
    if not get_tree().is_network_server():
        rpc_id(id, "register_player", my_info)
    
func _player_disconnected(id):
    print("Player " + str(id) + " disconnected")
    remove_player(id)
    player_info.erase(id) # Erase player from info.

########################################################

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
    player.set_network_master(1)
    
    
    
    # physics *only* performed on server
    if get_tree().is_network_server():
        player.call_deferred("enable_collisions", true)
        player.call_deferred("set_physics_process", true)
        
        var start_location = $SpawnPointsPlayers.get_child($Players.get_child_count()).transform
        player_info[id]["start_location"] = start_location
        
        player.call_deferred("set_global_transform", start_location)        

        
    else:
        player.call_deferred("enable_collisions", false)
    
    
    player.set_deferred("local_player", local_player)
    player.call_deferred("set_username", player_info[id]["name"])
    player.call_deferred("set_base_skin", player_info[id]["skin"])
    
    
    
    get_node("/root/Game/Players").add_child(player)
    
    player_info[id]["object"] = player
    

func add_robot(name):
    local_robot = add_robot_remote(name)
    
    if GameState.mode == GameState.SERVER:
        rpc("add_robot_remote", name)
    
puppet func add_robot_remote(name):
    print("Adding robot " + str(name))
    var robot = preload("res://RobotBridge.tscn").instance()
    
    robots[name] = robot
    
    robot.set_name(name)
    robot.set_deferred("robot_name", name)
    robot.set_deferred("game_instance", self)
    robot.get_node("LaserScanner").visible = show_laserscans
    
    # physics *only* performed on server
    if GameState.mode == GameState.SERVER or GameState.mode == GameState.STANDALONE:
        robot.enable_collisions(true)
        robot.call_deferred("set_physics_process", true)
        
        
    else:
        robot.enable_collisions(false)
    
    if GameState.mode == GameState.SERVER or GameState.mode == GameState.STANDALONE:
        
        var start_location = $SpawnPointsRobots.get_child($Robots.get_child_count()).transform
        robot.set_global_transform(start_location)
        
        robot.set_deferred("navigation", $MainOffice.nav)
    
    $Robots.add_child(robot)
    
    return robot

func toggle_robots_lasers(state):
    
    show_laserscans = state
    
    for robot in $Robots.get_children():
        robot.get_node("LaserScanner").visible = state

remote func pre_configure_game():
    
    var selfPeerID = "myself" # used in STANDALONE mode
    
    if GameState.mode == GameState.CLIENT:
        selfPeerID = get_tree().get_network_unique_id()  # used in CLIENT/SERVER mode
            
        get_tree().set_pause(true)

    
    # Load my player
    local_player = preload("res://Player.tscn").instance()
    local_player.set_name(str(selfPeerID))
    
    #local_player.set_network_master(selfPeerID)
    
    # the server is ultimately controlling the player position
    # -> the network master is 1 (eg, default)
    
    get_node("/root/Game/Players").add_child(local_player)
    
    var _err = $CanvasLayer/UI.connect("on_chat_msg", local_player, "say")
    _err = $CanvasLayer/UI.connect("on_expression", local_player, "set_expression")
    
    $MainOffice.set_local_player(local_player)

    if GameState.mode == GameState.CLIENT:
        # no local physics, all is managed by the server
        local_player.toggle_collisions(false)
        
        # Tell server (remember, server is always ID=1) that this peer is done pre-configuring.
        rpc_id(1, "done_preconfiguring", selfPeerID)
        
        print("Done pre-configuring game. Waiting for the server to un-pause me...")
    
    elif GameState.mode == GameState.STANDALONE:
        local_player.toggle_collisions(true)
        var start_location = $SpawnPointsPlayers.get_child($Players.get_child_count()).transform
        local_player.transform = start_location

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
    new_mission(who)
var debug_points = []

# draws a point at a given position in the world coordinates
func debug_point(pos):
    
    if pos in debug_points:
        return
    
    var point = MeshInstance.new()
    point.mesh = SphereMesh.new()
    point.mesh.radius = 0.03
    point.mesh.height = 0.06
   
    add_child(point)
    
    point.global_transform.origin = pos
    
    debug_points.append(pos)
    
    
######### save data ###########
var file = File.new()
var path ="res://logs"
var all_expr=["happy", "angry", "excited", "sad"]


#create a file and add the first line: the user id 
func create_file(name): 
    
    
    var path_modified = path + "/%s"%name + ".csv"
    
    file.open(path_modified ,file.WRITE)
    if not file.is_open():
        print("Error opening file: " + path_modified)
        return
    else: 
        print("file created for the user with id %s"%name )
    
    #file.store_line(dateRFC1123)
    #file.store_line("user : %s"%name )
    file.store_line( " time,x,z,rotation, expression, is_speaking")
    
    file.close()
    
func save_data(name, data): #save the data in the csv file nammed name.csv
    var path_modified = path + "/%s"%name + ".csv"
    file.open(path_modified,file.READ_WRITE)
    if not file.is_open():
        print("Error opening file: " + path_modified)
        return
    
    file.seek_end()
    file.store_line(data)
    
    file.close()


# for each player, this function will create and save a string on a csv file with the position, orientation and expression of the player
 
func pre_save(): 
    for p in $Players.get_children(): 
        var ID = p.get_name()
        
        var time = OS.get_unix_time()
        var mood = all_expr[p.expression]
        
        var data = "%s"%time+ "," + "%.2f"%p.global_transform.origin[0]+ "," + "%.2f"%p.global_transform.origin[2] +"," + "%.1f"%p.rotation_degrees[1] + "," + "%s"%mood + "," + "%s"%p.is_speaking
        save_data(ID,data)
        
        
        #print(player_info)
    #for who in player_info: 
        #print(who) # print the id of the player 
        
func time_played(): 
    time_now= OS.get_unix_time()
    var elapsed = time_now - time_start
    return elapsed

func show_time(): 
    var time_sec = total_time - time_played()
    if time_sec ==0: 
        show_message(' Time out !  END OF THE GAME')
    else : 
        var time_min =0
        while time_sec>59: 
            time_min+=1
            time_sec-=60
        var remaining_time=""
        if time_min>0: 
            remaining_time+= String(time_min)
        else: 
            remaining_time += '0'
        remaining_time+=":"
        if (time_sec > 9):
            remaining_time += String(time_sec)
        else:
            remaining_time += "0" + String(time_sec)
    
        $CanvasLayer/UI/Time.text = remaining_time
    
    
    
func _on_timer_save_timeout():
    if GameState.mode == GameState.SERVER:
        pre_save()
    pass # Replace with function body.

######     Mission 
remote func update_score(new_points):
    $CanvasLayer/UI.set_score(new_points)
    
#this function will show the description of the mission on the client's screen 
remote func show_mission(description): 
    
    $CanvasLayer/UI.set_mission_description(description)
    
remote func show_message(text): 
    $CanvasLayer/UI.show_message(text)
    

func shuffle_missions():
    var order = range($Missions.get_child_count())

    order.shuffle()
    for p in range(order.size()):
        var child = $Missions.get_child(order[p])
        $Missions.move_child(child, p)
        


func random_index(n): 
    
    var random_generator = RandomNumberGenerator.new()
    random_generator.randomize()
    var random_value = random_generator.randi_range(0, n-1)
    
    return int(random_value)



# this function will give a new mission to the player     
remote func new_mission(id):
    
    var nb_missions= $Missions.get_child_count()
    var id_mission=random_index(nb_missions)
    var index_target
    var mission = $Missions.get_child(id_mission)
    while $Players.get_child_count()==1 and mission.mission_with_target==true:
        id_mission=random_index(nb_missions)
        mission = $Missions.get_child(id_mission)
    if mission.mission_with_target==true: 
        var nb_players= $Players.get_child_count()
        index_target = random_index(nb_players)
        while int($Players.get_child(index_target).get_name())==int(id): 
            index_target = random_index(nb_players)
        
    
    var description = mission.description
    
    var character = get_node("Players/%s"%id)
    character.mission = "%s"%mission.get_name()
    if mission.mission_with_target==true: 
        var id_target = $Players.get_child(index_target).get_name()
        character.target_for_mission = id_target
  
        
        rpc_id(int(id),"show_mission","%s  "%id_target+description)
    else: 
        rpc_id(int(id),"show_mission",description)
    

#this function will check if players have done their missions      
func are_missions_done(): 
     for p in $Players.get_children(): 
        if p.mission == null  : 
            return
        var ID = p.get_name()
        if get_node("Missions/" + p.mission).mission_with_target==true: 
            var id_target =  p.target_for_mission
            var node_target = get_node("Players/%s"%id_target) 
            get_node("Missions/" + p.mission).is_mission_done(p,node_target) 
        elif get_node("Missions/" + p.mission).mission_with_object==true:
            var object = get_node("Missions/" + p.mission).object
            var node_object = get_node(object) 
            get_node("Missions/" + p.mission).is_mission_done(p,node_object) 
        else: 
            get_node("Missions/" + p.mission).is_mission_done(p)   
        if get_node("Missions/" + p.mission).mission_done ==true: 
            rpc_id(int(ID), "show_message","Mission Done ! ")
            rpc_id(int(ID),"update_score",1)
            get_node("Missions/" + p.mission).mission_done=false
            new_mission(ID)

