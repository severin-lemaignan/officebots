extends Spatial

var local_player

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var MAX_DIST_HANDLEHIGHLIGHT = 3.0

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

    if !local_player:
        return

    var dist = $HandleAnchor.get_global_transform().origin.distance_to(local_player.get_global_transform().origin)
    #print(str(dist) + " units from door handle")

    if dist < MAX_DIST_HANDLEHIGHLIGHT:

        $HandleHighlight.visible = true
        
        var screenPos = local_player.camera.unproject_position($HandleAnchor.get_global_transform().origin)
        $HandleHighlight.position = screenPos
            
        # Scale the speech bubble based on distance to player
        var s = max(0.5, 2 / dist)
        #print(str(s))
        $HandleHighlight.scale = Vector2(s, s)
        $HandleHighlight.modulate = Color(1,1,1,s-0.5)
    
    else:
        $HandleHighlight.visible = false

