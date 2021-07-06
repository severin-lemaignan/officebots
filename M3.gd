extends Node

var player 
var id_mission=3
var mission_done= false 
var mission_with_target = false 
var mission_with_object = false
var description = "behind pool table" 

# Called when the node enters the scene tree for the first time.
func _ready():
    print("your mission is " + description )
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func is_mission_done(p):
    var position = p.global_transform.origin[0]
    if position > 8.60 : 
        #mission_done = true 
        #print ("Mission %s"%id_mission + " is done for the player %s"%p.get_name())
        pass  # the var misson done is updated in the function 'on_M3_body_entered'
    return mission_done
    
    
    
#PickableObjects/Lunchbox


func _on_M3_body_entered(body):
    mission_done = true 
    print("body entered into M3 ")
    
