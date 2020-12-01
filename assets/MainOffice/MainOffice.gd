extends Spatial

onready var nav = $Navigation


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

# called by Game.gd upon player creation
func set_local_player(object):
    
    for d in $Doors.get_children():
        d.local_player = object
    
    for d in $PickableObjects.get_children():
        d.local_player = object


func get_navmesh():
    var navmesh = $Navigation/NavigationMeshInstance.navmesh
    var polygons = []
    for idx in navmesh.get_polygon_count():
        polygons.append(navmesh.get_polygon(idx))
    
    return polygons

