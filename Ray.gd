extends Spatial
class_name Ray


func set_angle(angle):
    rotation = Vector3(0,angle,0)

func set_distance(dist):
    $Impact.translation = Vector3(dist,0,0)
    $RaySurface.scale = Vector3(dist,0,0.02)
    $RaySurface.translation = Vector3(dist/2,0,0)
