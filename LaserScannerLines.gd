extends Spatial



var NB_RAYS = 20

func _ready():
    for i in range(NB_RAYS):
        var ray = Ray.new()
        add_child(ray)
        

func draw(ranges):

    var theta = PI / (NB_RAYS + 1)
    
    for i in range(NB_RAYS):
        var angle = theta * (i + 1)
        
        var ray = get_child(i)
        ray.set_distance(ranges[i])
        ray.set_angle(PI/2 + angle)
        
