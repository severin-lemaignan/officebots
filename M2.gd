extends Node

var player
var id_mission=2
var mission_done= false 
var mission_with_target = false 
var mission_with_object = true 
var object = "MainOffice/DynamicObstacles/OfficeChair7-1"
var description = "bring the office chair 7_2 near the coffee machine "

# Called when the node enters the scene tree for the first time.
func _ready():
    print("your mission is " + description )
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func is_mission_done(p,object):
    var position = object.global_transform.origin[2]
    if position > 6.5 : 
        mission_done = true 
        print ("Mission %s"%id_mission + " is done for the player %s"%p.get_name())
        
    return mission_done
    
