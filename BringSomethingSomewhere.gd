extends Node

var player 
var id_mission=2
var mission_done= false 
var mission_with_target= true
var mission_with_object = true
var description = "Bring: " #"bring the lunch box on the pool table  "
var points = 1
var target_player 
var target_zone 
var target_object 


func _ready():
    
    pass # Replace with function body.

func _process(delta):
    is_mission_done()
    pass 

func set_targets(object,zone): 
    target_object  = object 
    target_zone = zone 
    target_zone.target_object =  object
    target_zone.connect("target_detected",self,"on_target_detected")

func is_mission_done():
    var object_name
    if get_node_or_null("%s"%player) == null : 
        return  
    
    if target_object != null : 
        object_name= target_object.get_name()
        
        var path_nd_ob = "/root/Game/Players/"+ player.get_name() + "/PickupAnchor/" + object_name
        #get_node("/root/Game/Players/"+ player.get_name() )
        #print(path_nd_ob)
        if get_node_or_null(path_nd_ob) != null : 
            var obj = get_node(path_nd_ob)
            target_zone.target_object = obj
            
                
    pass


func on_target_detected(object):
    
    mission_done = true 
    
