extends Node
var mission_number
var player 
var id_mission=0
var mission_done= false 
var mission_with_target= true
var mission_with_object = false
var description = " have to go to the " #"bring a player on the pool table  "
var points = 7 
var target_player 
var target_zone 


func _ready():
    
    pass # Replace with function body.



func set_targets(player,zone): 
    target_player = player 
    target_zone = zone 
    target_zone.target_player =  player 
    target_zone.connect("target_detected",self,"on_target_detected")

func is_mission_done(): 
    pass


func on_target_detected(player):
    
    mission_done = true 
    
