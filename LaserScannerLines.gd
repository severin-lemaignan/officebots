extends Spatial

var ray_class = preload("res://Ray.tscn")

func _ready():
    
    var inc = PI / (get_parent().NB_RAYS - 1)
    
    var angle = -PI/2
    
    for i in range(get_parent().NB_RAYS):

        var ray = ray_class.instance()
        ray.name = "ray_" + str(i)
        ray.transform.origin = Vector3(0,0.2,0)
        ray.set_angle(angle)
        add_child(ray)
        
        angle += inc

func draw(ranges):

    for i in range(get_parent().NB_RAYS):
        var ray = get_child(i)
        
        if ranges[i] < 0:
            ray.visible = false
        else:
            ray.visible = true
            ray.set_distance(ranges[i])
