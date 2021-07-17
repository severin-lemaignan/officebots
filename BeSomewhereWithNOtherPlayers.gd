extends Node

var player 
var id_mission=4
var mission_done= false 
var mission_with_target= false
var mission_with_object = false
var number_targets=1
var description = "Be with %s players at the same time in "%number_targets 
var distance 
var target_player 
var target_zone 
var number_players_around = false
var in_zone=false
func _ready():
    
    pass # Replace with function body.



func set_targets(distance_gamestate,zone, player):
    target_zone = zone 
    target_zone.target_player =  player
    target_zone.connect("target_detected",self,"on_target_detected") 
    distance = distance_gamestate


func is_mission_done(players_distances, players ): 
    print(distance)
    print(players_distances)
    # doit trouver un moyen de faire players_distances[p1][p2]
    var player_distances = players_distances[player]
    var count= 0
    for p in players: 
        if p== player: 
            pass 
        elif players_distances[player][p] < distance : 
                count+= 1 
    if count >= number_targets: 
        if in_zone==true : 
            mission_done=true
            
        number_players_around = true
    else: 
        number_players_around = false
        
        
func on_target_detected(player):
    
    in_zone=true
    if number_players_around==true: 
        mission_done = true 
    

