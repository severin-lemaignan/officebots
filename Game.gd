extends Spatial

#const SERVER_URL="research.skadge.org"
const SERVER_URL="localhost"
const SERVER_PORT=6969

export (bool) var force_client : bool = false
var is_server : bool


export(String) var username = "John Doe"

# Player info, associate ID to data
var player_info = {}
# Info we send to other players
var my_info =  { "name": username, "favorite_color": Color8(255, 0, 255) }



func _ready():
    
    # the web version are always clients; the non-web versions are server (except if set to force client)
    if OS.get_name() == "HTML5" or force_client:
        is_server = false
        $ControlCamera.current = false
    else:
        is_server = true
        $ControlCamera.current = true
        
    var peer
    
    if is_server:
        print("STARTING AS SERVER")
        peer = WebSocketServer.new()
        
        # the last 'true' parameter enables the Godot high-level multiplayer API
        peer.listen(SERVER_PORT, PoolStringArray(), true)
        
    else:
        print("STARTING AS CLIENT")
        peer = WebSocketClient.new()
        
        # the last 'true' parameter enables the Godot high-level multiplayer API
        peer.connect_to_url(SERVER_URL + ":" + str(SERVER_PORT), PoolStringArray(), true)
    
    get_tree().network_peer = peer
    
    get_tree().connect("network_peer_connected", self, "_player_connected")
    get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
    

    get_tree().connect("connected_to_server", self, "_connected_ok")
    get_tree().connect("connection_failed", self, "_connected_fail")
    get_tree().connect("server_disconnected", self, "_server_disconnected")

func _process(_delta):
    
    # server & clients need to poll, according to https://docs.godotengine.org/en/stable/classes/class_websocketclient.html#description
    get_tree().network_peer.poll()

func remove_player(id):
    player_info[id]["object"].queue_free()
    
func add_player(id):
    print("Adding player " + str(id))
    var player = preload("res://Character.tscn").instance()
    
    player.set_name(str(id))
    player.set_network_master(id) # Will be explained later
    get_node("/root/Game/Players").add_child(player)
    
    player_info[id]["object"] = player


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
    var my_player = preload("res://Player.tscn").instance()
    my_player.set_name(str(selfPeerID))
    my_player.set_network_master(selfPeerID)
    get_node("/root/Game/Players").add_child(my_player)

    # Load other players
#    for p in player_info:
#        var player = preload("res://Player.tscn").instance()
#        player.set_name(str(p))
#        player.set_network_master(p) # Will be explained later
#        get_node("/root/Game/Players").add_child(player)

    # Tell server (remember, server is always ID=1) that this peer is done pre-configuring.
    rpc_id(1, "done_preconfiguring", selfPeerID)
    
    print("Done pre-configuring game. Waiting for the server to un-pause me...")

remote func post_configure_game():
    print("Starting the game!")
    get_tree().set_pause(false)


# Executed on the server only
var players_done = []
remote func done_preconfiguring(who):
    # Here are some checks you can do, for example
    assert(get_tree().is_network_server())
    assert(who in player_info) # Exists
    assert(not who in players_done) # Was not added yet

    print(player_info[who]["name"] + " is ready.")
    players_done.append(who)
    
    # wait for everyone to be ready
    #if players_done.size() == player_info.size():
    #    print("All players ready, starting the game!")
    #    rpc_id(who, "post_configure_game")
    
    # start the game immediately for whoever is connecting
    rpc_id(who, "post_configure_game")

