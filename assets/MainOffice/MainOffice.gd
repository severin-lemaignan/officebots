extends Node3D

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
	var navigation_mesh = $NavigationMeshInstance.navigation_mesh
	var polygons = []
	var vertices = navigation_mesh.get_vertices()
	
	for idx in navigation_mesh.get_polygon_count():
		var polygon = []
		for v in navigation_mesh.get_polygon(idx):
			var vertex = GameState.convert_coordinates_godot2robotics(global_transform * (vertices[v]))
			polygon.append([vertex.x, vertex.y, vertex.z])
		
		polygons.append(polygon)
	
	return polygons
