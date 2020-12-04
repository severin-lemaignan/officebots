extends Spatial

var ray_class = preload("res://Ray.tscn")

var NB_RAYS = 50
var RANGE = 20 #m

func _ready():
    
    var inc = PI / (NB_RAYS - 1)
    
    var angle = -PI/2
    
    for i in range(NB_RAYS):

        var ray = ray_class.instance()
        ray.name = "ray_" + str(i)
        add_child(ray)
        
        ray.transform.origin = Vector3(0,0,0)
        ray.rotate_y(angle)
        
        angle += inc

func draw(ranges):

    if visible:
        for i in range(NB_RAYS):
            var ray = get_child(i)
            #if ranges[i] < 0:
            if ranges[i] == Vector3(0,0,0):
                ray.visible = false
            else:
                ray.visible = true
                #ray.set_distance(ranges[i])
                ray.set_hitpoint(ranges[i])


func laser_scan():
    #get_parent().game_instance.debug_point(global_transform.origin)
    var space_state = get_world().direct_space_state
    var laser_ranges = []
    var laser_hitpoints = []
    
    var inc = PI / (NB_RAYS - 1)
    var angle = -PI/2

    for i in range(NB_RAYS):
        var target = global_transform.basis.xform(global_transform.origin + Vector3(0,0,RANGE).rotated(Vector3(0,1,0), angle))
        var result = space_state.intersect_ray(global_transform.origin, target)
        if result:
            #get_parent().game_instance.debug_point(result.position)
            laser_ranges.append(global_transform.origin.distance_to(result.position))
            laser_hitpoints.append(result.position - global_transform.origin)
        else:
            laser_ranges.append(-1)
            laser_hitpoints.append(Vector3(0,0,0))
            
        angle += inc

    #draw(laser_ranges)
    draw(laser_hitpoints)
    
    return laser_ranges
