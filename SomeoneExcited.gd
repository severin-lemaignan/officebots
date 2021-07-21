extends Node

var player 
var id_mission=7
var mission_done= false 
var mission_with_target= true
var mission_with_object = false
var description = " has to use the emoji happy" 
var points = 1
var target_player 
var target_zone 
var target_object 


func _ready():
    
    pass # Replace with function body.

func _process(delta):
    is_mission_done()
    pass 

func set_targets(target): 
    target_player= target
    


func is_mission_done():
    
    if target_player.name_expression == "happy" : 
        mission_done=true 
        
      
            
                
