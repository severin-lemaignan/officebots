extends Spatial

# this does not display the hit points at the right position, for an unclear reason.
# it looks as if the coordinates resulting from the rotation of Ray (in LaserScannerLines.gd) followed by
# the translation are transformed again somehow, following a weird inverse function... spent an hour
# trying to figure it out, to no avail
func set_distance(dist):
    $Impact.translation = Vector3(0,0,dist)
    $RaySurface.scale = Vector3(0.02,0,dist)
    $RaySurface.translation = Vector3(0,0,dist/2)

# z points forward
func set_hitpoint(pos : Vector3):
    $Impact.global_transform.origin = global_transform.origin + pos
    #var dist = pos.length()
    #$Impact.translation = Vector3(0, 0, dist)
    
    #$RaySurface.scale = Vector3(0.02,0,dist)
    #$RaySurface.translation = Vector3(0,0,dist/2)
    
