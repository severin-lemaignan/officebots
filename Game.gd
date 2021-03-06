extends Spatial

####### THESE ENUMS ARE *ONLY* FOR CONFIGURATION IN THE GODOT EDITOR UI ########
####### See GameState for the actual global variables used in the code #########

# set the initial game mode. Can be overridden by 
# command-line arguments --server, --client, --standalone
enum modes {UNSET, CLIENT, SERVER, STANDALONE}
export(modes) var run_as = modes.SERVER

# by default, the game supports adding robots; robots can be disabled if eg
# it is only played online with human users.
enum RobotsMode {ROBOTS, NO_ROBOTS}
export(RobotsMode) var has_robots = RobotsMode.ROBOTS

export(bool) var enable_focus_blur = true
###############################################################################

var SERVER_URL= "wss://research-ws.skadge.org" #"127.0.0.1"#

var SERVER_PORT=6969 # only used for the server -- the client will always connect to the default wss port (80 or 443)

var time_start=0 
var time_now=0
var total_time = 600 #total time of the game in seconds


var is_networking_started

var local_player
var player_name
var player_skin
var prolific_id 

# dictionary of ImageTexture created by users of the Python API when
# uploading images to the server.
# used eg to set the texture on the robots' screens
var screen_textures = {}

# if changing that, make sure to add spawn points accordingly
var MAX_PLAYERS = 10
var MIN_PLAYERS = 2

export(String) var username = "John Doe"

# Player info, associate ID to data
var player_info = {}

# stores the distances between players
var players_distances = {}

var robots = {}
var local_robot = null
var emotions = ["happy", "smily" , "laughing", "confused", "bored"]
# whether or not laserscans are displayed. Changed via the settings in the UI
# (cf callback 'toggle_robots_lasers')
var show_laserscans = false

var robot_server

onready var navmesh = $MainOffice.get_navmesh()

func _ready():
	
	$CanvasLayer/Effects/VignetteEffect.visible = enable_focus_blur
	$Timer_Lobby.connect("timeout",self,"_on_Timer_Lobby_timeout")
	$Timer_Lobby.wait_time = 10
	$Timer_Lobby.one_shot = true
	$timer_save.wait_time = 1
	$timer_save.one_shot = false 

	
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
			print("Setting the game server to " + SERVER_URL)
	
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
		$CanvasLayer/Effects.visible = false
	
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
		peer.connect_to_url(SERVER_URL, PoolStringArray(), true)
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
	
	# enable physics calculations for all the dynamics objects, *on the server only* (or in stand-alone mode)
	for o in $MainOffice/DynamicObstacles.get_children():
		o.call_deferred("set_physics_process", true)
	for o in $MainOffice/PickableObjects.get_children():
		o.call_deferred("set_physics_process", true)
	
	
func _process(_delta):
	
	
		
	if is_networking_started:
		
		
		if GameState.mode == GameState.SERVER or GameState.mode == GameState.CLIENT:
			# server & clients need to poll, according to https://docs.godotengine.org/en/stable/classes/class_websocketclient.html#description
			get_tree().network_peer.poll()
		if GameState.mode == GameState.SERVER: 
			update_time()
			update_players_proximity()
		
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
		#rpc_id(1,"create_file",str(id))
	if get_tree().is_network_server():
		create_file(str(id))
		
	if not get_tree().is_network_server():
		rpc_id(id, "register_player", my_info)
	
func _player_disconnected(id):
	print("Player " + str(id) + " disconnected")
	remove_player_mission(id)
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
	# THIS RUNS BOTH ON THE SERVER AND ON THE CLIENTS
	
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
		player.call_deferred("connect", "player_msg", $CanvasLayer/Chat, "add_msg")
	
	
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
	
	var _err = $CanvasLayer/Chat.connect("on_chat_msg", local_player, "say")
	_err = $CanvasLayer/Chat.connect("typing", local_player, "typing")
	_err = $CanvasLayer/Chat.connect("not_typing_anymore", local_player, "not_typing_anymore")
	_err = local_player.connect("player_list_updated", $CanvasLayer/Chat, "set_list_players_in_range")
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
	
	
	
	rpc_id(who,"questionnaire",who)
	

		

remote func lobby(who): 
	rpc_id(who,"show_lobby")   
	# start the game immediately for whoever is connecting, passing the
	# start location of the player
	players_done.append(who)
	update_lobby()
	
	if players_done.size()==MIN_PLAYERS:
		$Timer_Lobby.start()
	if players_done.size()>MIN_PLAYERS and $Timer_Lobby.time_left==0:
		acces_game_after_start(who)
	if players_done.size()==MAX_PLAYERS:
		$Timer_Lobby.stop()
		end_lobby()
	   

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
var path ="./logs"
var all_expr=["happy", "angry", "excited", "sad"]


#create a file and add the first line: the user id 
remote func create_file(name): 
	
	
	var path_modified = path + "/%s"%name + ".csv"
	
	file.open(path_modified ,file.WRITE)
	if not file.is_open():
		print("Error opening file: " + path_modified)
		return
	else:    
		print("file created for the user with id %s"%name )
	
	#file.store_line(dateRFC1123)
	#file.store_line("user : %s"%name )
	
	file.store_line( "ID, time, pos_x,pos_y,pos_z,r_x,r_y,r_z, expression, is_speaking, mission 1, mission 2, mission 3, score ")
	
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
		
		var mood=p.name_expression
		
		var data = "%s"%ID + "," + "%s"%time+ "," + "%.2f"%p.global_transform.origin[0]+ "," + "%.2f"%p.global_transform.origin[1]+"," + "%.2f"%p.global_transform.origin[2] +"," +"%.2f"%p.rotation_degrees[0]+"," + "%.2f"%p.rotation_degrees[1]+ "," + "%.2f"%p.rotation_degrees[2] + "," + mood + "," + "%s"%p.is_speaking() + "," + "%s"%p.mission_1 + "," + "%s"%p.mission_2 + "," + "%s"%p.mission_3 + "," + "%s"%p.score
		save_data(ID,data)
		
		
		#print(player_info)
	#for who in player_info: 
		#print(who) # print the id of the player 

##questionnaire and  saving data of the questionnaire : 


remote func questionnaire(who): 
	get_tree().set_pause(false)
	
	print("in questionnaire")
	$CanvasLayer/CharacterSelection.hide()
	$CanvasLayer/UI.hide()
	$QuestionsExplanations.show()
	$QuestionsExplanations.preHocQuestionnaire()

	var questionaire = yield($QuestionsExplanations,"questionaire_complete")

	prolific_id = questionaire

	$QuestionsExplanations.consent()
	var consent = yield($QuestionsExplanations,"consent_given")

	$QuestionsExplanations.big5()
	var big5_results = yield($QuestionsExplanations,"big5_complete")
	#save_big5(big5_results)

	yield(get_tree().create_timer(0.5), "timeout")
	$QuestionsExplanations.showIntro()

	yield($QuestionsExplanations,"intro_complete")  
	var results_str=""
	for i in big5_results: 
		results_str+="%s"%i
		   
	rpc_id(1,'save_q5',who, prolific_id, results_str) #,str(prolific_id),results_str)
	print("save q5")
	
	
	$CanvasLayer/CharacterSelection.show()
	$CanvasLayer/UI.show()      
	
	get_tree().set_pause(true)
	rpc_id(1, 'lobby', who)
	

remote func save_q5(who,prolific_id,results): 
	
	var path_modified = path + "/%s"%who + ".txt"
	
	file.open(path_modified ,file.WRITE)
	if not file.is_open():
		print("Error opening file: " + path_modified + "file q5")
		return
	else: 
		print("file created for the user with id " + "%s"%prolific_id + " file q5")
	
	#file.store_line(dateRFC1123)
	#file.store_line("user : %s"%name)
	file.store_line("%s"%prolific_id)
	file.store_line(results)
	
	
	file.close()

		
func time_played(): 
	time_now= OS.get_unix_time()
	var elapsed = time_now - time_start
	return elapsed

func update_time(): 
	var time_sec = total_time - time_played()
	if time_sec == 0: 
		
		show_message(' Time out !  END OF THE GAME')
		var max_score= 0 
		var ranking=[]
		var list_score=[]
		for p in $Players.get_children(): 
			if p.score >max_score: 
				max_score=p.score
		for i in range(max_score+2,-100,-1): 
			for p in $Players.get_children(): 
				if p.score ==i:
					var name = player_info[int(p.get_name())]["name"]
					ranking.append(str(name))
					list_score.append(str(i))
		$timer_save.stop()
		for p in $Players.get_children(): 
			rpc_id(int(p.get_name()),"show_lobby_end",ranking,list_score)
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
		for p in $Players.get_children():
			var ID = p.get_name()
			$CanvasLayer/UI/Time.text  = remaining_time
			
			rpc_id(int(ID),'show_time', remaining_time)
	
remote func show_time(remaining_time): 
	$CanvasLayer/UI/Time.text  = remaining_time
	
func _on_timer_save_timeout():
	if GameState.mode == GameState.SERVER:
		pre_save()
	pass # Replace with function body.

func update_players_proximity():
	# only executed on server
	
	var players = $Players.get_children()
	
	var proximity = {}
	
	var min_dist = GameState.DISTANCE_AUDIBLE * GameState.DISTANCE_AUDIBLE
	
	for idx in range(players.size()):
		var p1 = players[idx]
		if not players_distances.has(p1):
			players_distances[p1] = {}
			
		for idx2 in range(idx + 1, players.size()):
			var p2 = players[idx2]
			if not players_distances.has(p2):
				players_distances[p2] = {}
			
			var dist = p1.translation.distance_squared_to(p2.translation)
			
			if not players_distances[p1].has(p2):
				players_distances[p1][p2] = dist
			
			if not players_distances[p2].has(p1):
				players_distances[p2][p1] = dist
			
			var prev_dist = players_distances[p1][p2]
			
			if dist < min_dist and prev_dist > min_dist:
				# p1 and p2 are now in range
				if not proximity.has(p1):
					proximity[p1] = {"in_range":[p2.name], "not_in_range":[]}
				else:
					proximity[p1]["in_range"].append(p2.name)
				
				if not proximity.has(p2):
					proximity[p2] = {"in_range":[p1.name], "not_in_range":[]}
				else:
					proximity[p2]["in_range"].append(p1.name)
				
				print(p1.username + " and " + p2.username + " in range")
				$CanvasLayer/Chat.add_msg(p1.username + " and " + p2.username + " in range", "[SERVER]")
			
			elif dist > min_dist and prev_dist < min_dist:
				# p1 and p2 are not in range anymore
				if not proximity.has(p1):
					proximity[p1] = {"in_range":[], "not_in_range":[p2.name]}
				else:
					proximity[p1]["not_in_range"].append(p2.name)
				
				if not proximity.has(p2):
					proximity[p2] = {"in_range":[], "not_in_range":[p1.name]}
				else:
					proximity[p2]["not_in_range"].append(p1.name)
				
				print(p1.username + " and " + p2.username + " not in range anymore")
				$CanvasLayer/Chat.add_msg(p1.username + " and " + p2.username + " not in range anymore")
			
			players_distances[p1][p2] = dist
			players_distances[p2][p1] = dist
   
	for p in proximity:
		p.rpc("puppet_update_players_in_range", proximity[p]["in_range"],proximity[p]["not_in_range"])
		
######     Mission 
remote func update_score(new_points):
	$CanvasLayer/UI.set_score(new_points)
	
#this function will show the description of the mission on the client's screen 
remote func show_mission(description,mission_number): 
	
	$CanvasLayer/UI.set_mission_description(description,mission_number)
	
remote func show_message(text): 
	$CanvasLayer/UI.show_message(text)


func random_index(n): 
	
	var random_generator = RandomNumberGenerator.new()
	random_generator.randomize()
	var random_value = random_generator.randi_range(0, n-1)
	
	return int(random_value)



# this function will give a new mission to the player   
var mission_ongoing=[]
func mission_free(id):
	for i in mission_ongoing: 
		if i==id: 
			return false
	return true 
	return true 
	
remote func new_mission(id, mission_number):
	
	var nb_missions = 8#get_node("Missions").get_child_count()
	var index_mission = random_index (nb_missions)
	var index_target
	var path_mission
	if $Players.get_child_count()!=1: 
		while get_node("Players/%s"%id).mission_1==index_mission or get_node("Players/%s"%id).mission_2==index_mission  or get_node("Players/%s"%id).mission_3==index_mission :
			index_mission = random_index(nb_missions) 
		
	if $Players.get_child_count()==1: 
		index_mission=5
	if index_mission ==0 : 
		path_mission= "res://Missions/BringSomeoneSomewhere.tscn"
	if index_mission ==1 : 
		path_mission = "res://Missions/GoSomewhere.tscn"
	if index_mission ==2 : 
		path_mission = "res://Missions/BringSomethingSomewhere.tscn"  
	if index_mission == 3 : 
		path_mission = "res://Missions/BeCloseToSomeone.tscn"  
	if index_mission == 4 : 
		path_mission = "res://Missions/BeSomewhereWithNOtherPlayers.tscn"
	if index_mission == 5 : 
		path_mission = "res://Missions/FindSomething.tscn"
	if index_mission == 6 : 
		path_mission = "res://Missions/SpeakWithSomeone.tscn"
	if index_mission == 7 : 
		path_mission = "res://Missions/SomeoneExcited.tscn"
	var mission = load(path_mission).instance()
 
	var id_mission = mission.id_mission
	mission.mission_number=mission_number
	var player=get_node("Players/%s"%id)
	mission.player = player
#    while ($Players.get_child_count()==1 and mission.mission_with_target==true) or (mission_free(id_mission)==false):
#        id_mission=random_index(nb_missions)
#        path_mission = "res://M%s.tscn"%(id_mission+1)
#        mission = load(path_mission).instance()
	mission_ongoing.append(id_mission)
	var object 
	var target_zone 
	var target_player
	
	if mission.mission_with_object == true :
		
		var index_object= random_index ($MainOffice/PickableObjects.get_child_count()-1)
		object = get_node("MainOffice/PickableObjects").get_child(index_object+1)
		while object.pickable==false: 
			index_object= random_index ($MainOffice/PickableObjects.get_child_count()-1)
			object = get_node("MainOffice/PickableObjects").get_child(index_object+1)
		
		
	var index_zone= random_index ($Mission_Target.get_child_count())
	
	target_zone = get_node("Mission_Target").get_child(index_zone)
	#mission.target_zone=zone
	var location = target_zone.get_name()
	var description =  mission.description


	if mission.mission_with_target==true: 
		var nb_players= $Players.get_child_count()
		index_target = random_index(nb_players)
		while int($Players.get_child(index_target).get_name())==int(id): 
			index_target = random_index(nb_players)
		target_player=$Players.get_child(index_target)
	if mission.id_mission ==0: 
		var name_target = player_info[int(target_player.get_name())]["name"]
		description = name_target  + description + location
	if mission.id_mission==1: 
		description +=  location     
	if mission.id_mission==2: 
		description +=  object.get_name() + " to " + location    
	if mission.id_mission==4: 
		description +=   " the " + location   
	if mission.id_mission==5: 
		description+=object.get_name() 
	if mission.id_mission==6 : 
		var name_target = player_info[int(target_player.get_name())]["name"]
		description = name_target + description
	if mission.id_mission==7: 
		var index_em= random_index(4)
		mission.target_emotion = emotions[index_em]
		var name_target = player_info[int(target_player.get_name())]["name"]
		description = name_target + description + mission.target_emotion
	description+= "  | + %s points "%mission.points
	rpc_id(int(id),"show_mission",description,mission_number)
	if mission_number==1: 
		player.mission_1=mission.id_mission  
	if mission_number==2: 
		player.mission_2=mission.id_mission
	if mission_number==3: 
		player.mission_3=mission.id_mission   
	
	if mission.id_mission ==0: 
		mission.set_targets(target_player,target_zone)
	if mission.id_mission==1: 
		mission.set_targets(player,target_zone)
	if mission.id_mission==2: 
		mission.set_targets(object,target_zone)
	if mission.id_mission == 3 : 
		mission.set_targets(GameState.DISTANCE_AUDIBLE * GameState.DISTANCE_AUDIBLE)
	if mission.id_mission == 4 : 
		mission.set_targets(GameState.DISTANCE_AUDIBLE * GameState.DISTANCE_AUDIBLE,target_zone,player)
	if mission.id_mission==5: 
		mission.set_targets(object)
	if mission.id_mission==6 or mission.id_mission==7 : 
		mission.set_targets(target_player)
	
	#mission.set_name(id)
	get_node("Missions").add_child(mission)   
	
	
   
	
	
	
func remove_player_mission(id): 
	if $Missions.get_child_count()==0: 
		return  
	for m in $Missions.get_children():
		if m.mission_with_target==true : 
			if get_node_or_null("%s"%m.target_player) ==null : 
				var mission_number= m.mission_number
				var id_player_mission 
				if get_node_or_null("%s"%m.player) ==null: 
					return 
				else: 
					id_player_mission = m.player.get_name()
					new_mission(id_player_mission,mission_number) 
				
	print("removed disconnected player from missions")  
	
	
	
	
	

#this function will check if players have done their missions 




	 
func are_missions_done():
	
	if $Missions.get_child_count()==0: 
		return  
	for m in $Missions.get_children():
		if m.id_mission==2 or m.id_mission==6 or m.id_mission==7: 
			m.is_mission_done()
		if m.id_mission==3: 
			var players = $Players.get_children()
			m.is_mission_done(players_distances, players)
		if m.id_mission==4: 
			var players = $Players.get_children()
			m.is_mission_done(players_distances, players )
		if m.mission_done == true :
			m.mission_done = false
			var id_mission=m.id_mission
			var mission_number = m.mission_number
			var ID = m.player.get_name()
			var points = int(m.points)
			rpc_id(int(ID), "show_message","Mission Done ! ")
			rpc_id(int(ID),"update_score",points )
			get_node("Players/%s"%int(ID)).score+=points 
			if m.target_zone!=null : 
				m.target_zone.target_player = null
				m.target_zone.target_object = null  
			m.free()
			var i = mission_ongoing.find(id_mission)
			mission_ongoing.remove(i)
			#mission_ongoing.remove(mission_ongoing.index(id_mission))
			

			new_mission(ID,mission_number)
			 
######### LOBBY###############
remote func show_lobby(): 
	$CanvasLayer/UI/Lobby_Start.show_lobby()
remote func hide_lobby(): 
	$CanvasLayer/UI/Lobby_Start.hide_lobby()
	
	
func update_lobby():
	var number_player=players_done.size()+1
	
	for i in range (number_player-1):
		
		var id_player=players_done[i-1]
		
		var name_player = player_info[id_player]["name"]
		for p in $Players.get_children(): 
			rpc_id(int(p.get_name()),"add_player_lobby",i+1,name_player) 
		
		
remote func add_player_lobby(player,name): 
	   get_node("CanvasLayer/UI/Lobby_Start/VBoxContainer/Player%s"%player).text="Player %s  : "%player + name

remote func show_lobby_end(ranking,list_score): 
	$CanvasLayer/UI/Lobby_End.show_lobby()

	
	var i = 1
	for p in ranking:
		var score = list_score[i-1]
		get_node("CanvasLayer/UI/Lobby_End/HBoxContainer/VBoxContainer2/Player%s"%i).text= str(p)+ " " + str(score) + " points"
		i+=1
func acces_game_after_start(p): 
	rpc_id(p, "post_configure_game", player_info[p]["start_location"])
	new_mission(p,1)
	new_mission(p,2)
	new_mission(p,3)
	rpc_id(p,"hide_lobby")
		
func end_lobby(): 
	time_start= OS.get_unix_time()
	$timer_save.start()
	for p in players_done:
			
		rpc_id(p, "post_configure_game", player_info[p]["start_location"])
		new_mission(p,1)
		new_mission(p,2)
		new_mission(p,3)
		rpc_id(p,"hide_lobby")
		

func _on_Timer_Lobby_timeout():
	end_lobby()
	pass # Replace with function body.

func on_change_mission(id):
	rpc_id(1,"change_mission_from_server",id) 
	

remote func change_mission_from_server(id): 
	var id_sender = get_tree().get_rpc_sender_id()
	new_mission(id_sender,id)
	get_node("Players/%s"%id_sender).score -=3




func _on_Button_M1_button_down():
	show_message("new mission ")
	update_score(-3)
	rpc_id(1,"change_mission_from_server",1) 

func _on_Button_M2_button_down():
	show_message("new mission ")
	update_score(-3)
	rpc_id(1,"change_mission_from_server",2) 


func _on_Button_M3_button_down():
	show_message("new mission ")
	update_score(-3)
	rpc_id(1,"change_mission_from_server",3) 
