extends Spatial



var NB_RAYS = 1

func _ready():
    for i in range(NB_RAYS):
        var rayholder = Spatial.new()
        var ray = MeshInstance.new()
        ray.mesh = PlaneMesh.new()
        
        rayholder.add_child(ray)
        
        ray.translate(Vector3(1,0,0))
        ray.scale = Vector3(1,1,0.01)
        
        add_child(rayholder)
        

func draw(ranges):

    for idx in range(ranges.size()):
        get_child(idx).scale = Vector3(ranges[idx],1,1)
        
