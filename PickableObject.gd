extends RigidBody

var local_player

enum OBJECT_STATE {
    picked,
    resting
   }

var state = OBJECT_STATE.resting

var MAX_DIST_HIGHLIGHT = 3.0

func _ready():
    
    $Highlight.visible = false
    
    var _err = $Highlight.connect("highlight_clicked", self, "on_highlight_clicked")

func on_highlight_clicked():

    local_player.pickup_object(self)
    
#    match state:
#        OBJECT_STATE.resting:
#            local_player.pickup_object(self)
#            state = OBJECT_STATE.picked
#        OBJECT_STATE.picked:
#            local_player.release_object(self)
#            state = OBJECT_STATE.resting

func _process(_delta):

    if !local_player:
        return

    var dist = get_global_transform().origin.distance_to(local_player.get_global_transform().origin)
    #print(str(dist) + " units from door handle")

    if dist < MAX_DIST_HIGHLIGHT:

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

