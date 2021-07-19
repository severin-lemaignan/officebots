extends StaticBody

var local_player

enum DOOR_STATE {
    closed,
    half_open,
    open
   }

export(DOOR_STATE) var initial_state

export(float) var open_angle = -90
export(float) var half_open_angle = -40
export(float) var closed_angle = 0

var state

var MAX_DIST_HANDLEHIGHLIGHT = 3.0

# Called when the node enters the scene tree for the first time.
func _ready():
    $HandleHighlight.visible = false
    
    state = initial_state
    
    var _err = $HandleHighlight.connect("highlight_clicked", self, "on_handle_clicked")

remotesync func set_state(new_state):
    $Tween.remove_all()
    match new_state:
        DOOR_STATE.half_open:
            $Tween.interpolate_property(self, "rotation_degrees:y", null, half_open_angle, 1.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
            state = DOOR_STATE.half_open
        DOOR_STATE.open:
            $Tween.interpolate_property(self, "rotation_degrees:y", null, open_angle, 1.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
            state = DOOR_STATE.open
        DOOR_STATE.closed:
            $Tween.interpolate_property(self, "rotation_degrees:y", null, closed_angle, 2.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
            state = DOOR_STATE.closed
    
    $Tween.start()

func on_handle_clicked():
    match state:
        DOOR_STATE.closed:
            rpc("set_state", DOOR_STATE.half_open)
        DOOR_STATE.half_open:
            rpc("set_state", DOOR_STATE.open)
        DOOR_STATE.open:
            rpc("set_state", DOOR_STATE.closed)
            
func _process(_delta):

    if !local_player:
        return

    var dist = $HandleAnchor.get_global_transform().origin.distance_to(local_player.get_global_transform().origin)
    #print(str(dist) + " units from door handle")
    
    if dist < MAX_DIST_HANDLEHIGHLIGHT and \
       local_player.is_facing($HandleAnchor.global_transform.origin):

        $HandleHighlight.visible = true
        
        var screenPos = local_player.camera.unproject_position($HandleAnchor.get_global_transform().origin)
        $HandleHighlight.position = screenPos
            
        # Scale the speech bubble based on distance to player
        var s = max(0.5, 2 / dist)
        #print(str(s))
        $HandleHighlight.scale = Vector2(s, s)
        $HandleHighlight.modulate = Color(1,1,1,min(0.6, s-0.5))
    
    else:
        $HandleHighlight.visible = false

