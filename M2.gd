extends Node

  
var id_mission=2
var mission_done= false 
var mission_with_target = false 

var description = "the coffee machine "

# Called when the node enters the scene tree for the first time.
func _ready():
    print("your mission is " + description )
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func is_mission_done(p):
    var position = p.global_transform.origin[2]
    if position > 6.5 : 
        mission_done = true 
        print ("Mission %s"%id_mission + " is done for the player %s"%p.get_name())
        
    return mission_done
    