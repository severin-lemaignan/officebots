extends Spatial

# To start as a server, pass --server on the cmd line

#const SERVER_URL="research.skadge.org"
const SERVER_URL="localhost"
const SERVER_PORT=6969

var is_server : bool

var local_player

# if changing that, make sure to add spawn points accordingly
var MAX_PLAYERS = 10

export(String) var username = "John Doe"

# Player info, associate ID to data
var player_info = {}
# Info we send to other players
var my_info =  { "name": username, "favorite_color": Color8(255, 0, 255) }



func _ready():
    
    randomize()
    
    var arguments = {"server": false}
    for argument in OS.get_cmdline_args():
        if argument.find("=") > -1:
            var key_value = argument.split("=")
            arguments[key_value[0].lstrip("--")] = key_value[1]
        if argument == "--server":
            arguments["server"] = true
            
    # the web version are always clients;
    # the non-web versions are server iff '--server' argument is passed
    if OS.get_name() == "HTML5" or not arguments["server"]:
        is_server = false
        $FakePlayer/ControlCamera.current = false
    else:
        is_server = true
        $FakePlayer/ControlCamera.current = true
        $CanvasLayer/UI.visible = false
        
    var peer
    
    if is_server:
        print("STARTING AS SERVER")
        peer = WebSocketServer.new()
        
        # the last 'true' parameter enables the Godot high-level multiplayer API
        peer.listen(SERVER_PORT, PoolStringArray(), true)
        
        shuffle_spawn_points()
        local_player = $FakePlayer
        
    else:
        print("STARTING AS CLIENT")
        peer = WebSocketClient.new()
        
        # the last 'true' parameter enables the Godot high-level multiplayer API
        peer.connect_to_url(SERVER_URL + ":" + str(SERVER_PORT), PoolStringArray(), true)
        
        Input.set_default_cursor_shape(Input.CURSOR_DRAG)
    
    get_tree().network_peer = peer
    
    get_tree().connect("network_peer_connected", self, "_player_connected")
    get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
    

    get_tree().connect("connected_to_server", self, "_connected_ok")
    get_tree().connect("connection_failed", self, "_connected_fail")
    get_tree().connect("server_disconnected", self, "_server_disconnected")
    
    
    $Robot.navigation = $MainOffice.nav

    

func _process(_delta):
    
    # server & clients need to poll, according to https://docs.godotengine.org/en/stable/classes/class_websocketclient.html#description
    get_tree().network_peer.poll()


func shuffle_spawn_points():
    var order = [0,1,2,3,4,5,6,7,8,9].shuffle()
    
    for p in range(10):
        var child = $SpawnPointsPlayers.get_child(order[p])
        $SpawnPointsPlayers.move_child(child, p)
        

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
    print("New player " + str(id) + " joined")
    if not get_tree().is_network_server():
        rpc_id(id, "register_player", my_info)
    
func _player_disconnected(id):
    print("Player " + str(id) + " disconnected")
    remove_player(id)
    player_info.erase(id) # Erase player from info.

########################################################

remote func register_player(info):
    # Get the id of the RPC sender.
    var id = get_tree().get_rpc_sender_id()
    # Store the info
    player_info[id] = info
    
    add_player(id)
    
    if get_tree().is_network_server():
        print("New player connected: " + info["name"])

remote func pre_configure_game():
    var selfPeerID = get_tree().get_network_unique_id()
    
    get_tree().set_pause(true)

    # Load world
    #var world = load(which_level).instance()
    #get_node("/root").add_child(world)


    # Load my player
    local_player = preload("res://Player.tscn").instance()
    local_player.set_name(str(selfPeerID))
    local_player.set_network_master(selfPeerID)
    get_node("/root/Game/Players").add_child(local_player)
    
    $CanvasLayer/UI.connect("on_chat_msg", local_player, "say")
    $MainOffice.set_local_player(local_player)

    # Load other players
#    for p in player_info:
#        var player = preload("res://Player.tscn").instance()
#        player.set_name(str(p))
#        player.set_network_master(p) # Will be explained later
#        get_node("/root/Game/Players").add_child(player)

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

func remove_player(id):
    player_info[id]["object"].queue_free()
    
func add_player(id):
    print("Adding player " + str(id))
    var player = preload("res://Character.tscn").instance()
    
    player.set_name(str(id))
    player.set_network_master(id)
    
    player.local_player = local_player
    
    get_node("/root/Game/Players").add_child(player)
    
    player_info[id]["object"] = player


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
        
    print(player_info[who]["name"] + " is ready.")
    players_done.append(who)
    
    # wait for everyone to be ready
    #if players_done.size() == player_info.size():
    #    print("All players ready, starting the game!")
    #    rpc_id(who, "post_configure_game")
    
    # start the game immediately for whoever is connecting, passing the
    # start location of the player
    var start_location = $SpawnPointsPlayers.get_child(players_done.size() - 1).transform
    rpc_id(who, "post_configure_game", start_location)

