

extends Node

var player 
var id_mission=1
var mission_done= false 
var mission_with_target= false
var mission_with_object = false
var description = "Go to : " #"bring the lunch box on the pool table  "

var target_player 
var target_zone 


func _ready():
    
    pass # Replace with function body.



func set_targets(player,zone): 
    target_player = player 
    print(player)
    
    
    target_zone = zone 
    target_zone.target_player =  player 
    target_zone.connect("target_detected",self,"on_target_detected")
    print(zone.target_player)
    print("set_target done")
func is_mission_done(): 
    
    pass


func on_target_detected(player):
    
    mission_done = true 
    
