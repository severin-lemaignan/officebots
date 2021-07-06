extends Node

var player 
var id_mission=1
var mission_done= false 
var mission_with_target= false
var mission_with_object = false
var description = "the end of the corridor" #"bring the lunch box on the pool table  "

func _ready():
    print("your mission is " + description )
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func is_mission_done(p):
    var position = p.global_transform.origin[0]
    if position < -15 : 
        #mission_done = true 
        #print ("Mission %s"%id_mission + " is done for the player %s"%p.get_name())
        pass
    return mission_done
    
#PickableObjects/Lunchbox


func _on_M1_body_entered(player):
    
    mission_done = true 
    
