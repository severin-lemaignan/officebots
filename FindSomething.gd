extends Node
var mission_number
var player 
var id_mission=5
var mission_done= false 
var mission_with_target= false
var mission_with_object = true
var description = "Find and pick up  " 
var points = 1
var target_player 
var target_zone 
var target_object 


func _ready():
    
    pass # Replace with function body.

func _process(delta):
    is_mission_done()
    pass 

func set_targets(object): 
    target_object  = object 
     
    
    

func is_mission_done():
    var object_name
    if target_object != null : 
        if get_node_or_null("player")==null: 
            return 
        else : 
            
            object_name= target_object.get_name()
        
            var path_nd_ob = "/root/Game/Players/"+ player.get_name() + "/PickupAnchor/" + object_name

            if get_node_or_null(path_nd_ob) != null : 
                mission_done = true
            
                
    pass

