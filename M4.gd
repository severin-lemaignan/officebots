extends Node



var player
var id_mission=3
var mission_done = false 
var mission_with_target = true 
var mission_with_object = false
var target 

var description = "needs to go behind the pool table " 

#var target = true 
#var room = true 


# Called when the node enters the scene tree for the first time.
func _ready():
    print("your mission is " + description )
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    is_mission_done(player,target)
# check if the mission is over 
func is_mission_done(): 
    print ("in is mission done M4")


    var position = target.global_transform.origin[0]
    if position > 8.60 : 
        mission_done = true 
        print ("Mission M4 done ")

    return mission_done
    
    
#PickableObjects/Lunchbox
