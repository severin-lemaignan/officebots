extends Node

var player
var id_mission=1
var mission_done= false 
var mission_with_target = false 
var mission_with_object = true 
var object_path = "MainOffice/DynamicObstacles/OfficeChair7-1"
var description = "move the office chair 7_1 to the coffee machine "#"move the RubixCube to the coffee machine "
var object 


func _ready():
    
    print("your mission is " + description )
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
func is_mission_done(): 
    is_mission_m2_done(player,object)

func is_mission_m2_done(p,o):
    var position = o.global_transform.origin[2]
    if position > 6.5 : 
        mission_done = true 
        print ("Mission %s"%id_mission + " is done for the player %s"%p.get_name())
        
    return mission_done
    
