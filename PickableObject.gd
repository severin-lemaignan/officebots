extends RigidBody

var local_player

enum OBJECT_STATE {
    picked,
    resting
   }

export(float, 0, 2, 0.1) var pickup_area_size = 1.0

var state = OBJECT_STATE.resting

var MAX_DIST_HIGHLIGHT = 3.0

func _ready():
    
    $Highlight.visible = false
    
    var _err = $Highlight.connect("highlight_clicked", self, "on_highlight_clicked")

    $Highlight.set_scale(pickup_area_size)
    
func on_highlight_clicked():

    local_player.pickup_object(self)
   
func _process(_delta):

    if !local_player:
        return

    var dist = get_global_transform().origin.distance_to(local_player.get_global_transform().origin)
    #print(str(dist) + " units from door handle")

    if dist < MAX_DIST_HIGHLIGHT and \
        local_player.is_facing(get_global_transform().origin):

        $Highlight.visible = true
        
        var screenPos = local_player.camera.unproject_position(get_global_transform().origin)
        $Highlight.position = screenPos
            
        # Scale the speech bubble based on distance to player
        var s = max(0.5, 2 / dist)
        #print(str(s))
        $Highlight.scale = Vector2(s, s)
        $Highlight.modulate = Color(1,1,1,min(0.6, s-0.5))
    
    else:
        $Highlight.visible = false
