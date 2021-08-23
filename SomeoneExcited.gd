extends Node
var mission_number
var player 
var id_mission=7
var mission_done= false 
var mission_with_target= true
var mission_with_object = false
var description = " has to use the emoji " 
var points = 10
var target_player 
var target_zone 
var target_object 

var target_emotion


func _ready():
    pass


func _process(delta):
    is_mission_done()
    pass 

func set_targets(target): 
    target_player= target
    


func is_mission_done():
    if target_player==null: 
        print("no target happy mission")
        return 
    
    if target_player.name_expression == target_emotion : 
        mission_done=true 
        
      
            
                
