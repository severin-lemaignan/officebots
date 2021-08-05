extends Node
var mission_number
var player 
var id_mission=3
var mission_done= false 
var mission_with_target= false
var mission_with_object = false
var number_targets=1
var description = "Be in a group with %s players "%number_targets 
var distance 
var target_player 
var target_zone 
var points = 3

func _ready():
    
    pass # Replace with function body.



func set_targets(distance_gamestate): 
    distance = distance_gamestate


func is_mission_done(players_distances, players ): 
    if get_node_or_null("player")==null: 
        return 
    var player_distances = players_distances[player]
    var count= 0
    for p in players: 
        if p== player: 
            pass 
        elif players_distances[player][p] < distance : 
                count+= 1 
    if count >= number_targets: 
        mission_done = true
    else: 
        pass 

