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
        ray.transform.origin = Vector3(0,0,0)
        ray.set_angle(angle)
        add_child(ray)
        
        angle += inc

func draw(ranges):

    if visible:
        for i in range(NB_RAYS):
            var ray = get_child(i)
            
            if ranges[i] < 0:
                ray.visible = false
            else:
                ray.visible = true
                ray.set_distance(ranges[i])


func laser_scan():
    var space_state = get_world().direct_space_state
    var laser_ranges = []
    
    var theta = PI / (NB_RAYS + 1)
    for i in range(NB_RAYS):
        var angle = theta * (i + 1)
        var target = global_transform.basis.xform(global_transform.origin + Vector3(0,0,RANGE).rotated(Vector3(0,1,0), angle))
        var result = space_state.intersect_ray(global_transform.origin, target)
        if result:
            laser_ranges.append(global_transform.origin.distance_to(result.position))
        else:
            laser_ranges.append(-1)

    draw(laser_ranges)
    
    return laser_ranges
