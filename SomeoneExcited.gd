extends Node
var mission_number
var player 
var id_mission=7
var mission_done= false 
var mission_with_target= true
var mission_with_object = false
var description = " has to use the emoji happy" 
var points = 10
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
    if get_node_or_null("target_player")==null: 
        return 
    print(target_player.name_expression)
    if target_player.name_expression == "happy" : 
        mission_done=true 
        
      
            
                
