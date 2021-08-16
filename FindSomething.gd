extends Node
var mission_number
var player 
var id_mission=5
var mission_done= false 
var mission_with_target= false
var mission_with_object = true
var description = "Find and pick up  " 
var points = 3
var target_player 
var target_zone 
var target_object_name


func _ready():
    
    pass # Replace with function body.

func _process(delta):
    is_mission_done()
    pass 

func set_targets(object): 
    target_object_name  = object.get_name() 
     
    
    

func is_mission_done():
    var object_name
    if target_object_name != null : 
        if player==null: 
            print("no more player ")
            return 
        else : 
            
            
        
            var path_nd_ob = "/root/Game/Players/"+ player.get_name() + "/PickupAnchor/" + target_object_name
            
            if get_node_or_null(path_nd_ob) != null : 
                mission_done = true
            
                
    pass

