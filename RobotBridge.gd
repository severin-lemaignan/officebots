extends Node

#const SERVER_URL="research.skadge.org"
const SERVER_URL="localhost"
const SERVER_PORT=6970

var server

func _ready():
    
    print("STARTING ROBOT BRIDGE SERVER")
    server = WebSocketServer.new()
    
    # the last 'false' parameter disables the Godot high-level multiplayer API
    server.listen(SERVER_PORT, PoolStringArray(), false)
    
    
    server.connect("client_connected", self, "_robot_connected")
    server.connect("client_disconnected", self, "_robot_disconnected")
    
    server.connect("data_received", self, "_on_robot_data")


func _process(_delta):
    
    server.poll()



##### NETWORK SIGNALS HANDLERS #####
    
func _robot_connected(id, protocol):
    # Called on both clients and server when a peer connects. Send my info to it.
    print("New robot " + str(id) + " joined (protocol: " + protocol + ")")
    
func _robot_disconnected(id, was_clean_close):
    print("Robot " + str(id) + " disconnected")

func _on_robot_data(id):
    var data = server.get_peer(id).get_packet()
    
    var helo = data.get_string_from_utf8()
    print("Peer said: " + helo)
    
    server.get_peer(id).put_packet(("Hello " + helo).to_utf8())
########################################################
