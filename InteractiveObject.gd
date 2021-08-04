extends RigidBody
class_name InteractiveObject

var local_player

export var pickable = true


enum OBJECT_STATE {
    picked,
    resting
   }

export(float, 0, 2, 0.1) var pickup_area_size = 1.0

var state = OBJECT_STATE.resting

var MAX_DIST_HIGHLIGHT = 6.0

var prev_transform

func _ready():
    
    if pickable:
        $Highlight.visible = false
        
        var _err = $Highlight.connect("highlight_clicked", self, "on_highlight_clicked")

        $Highlight.set_scale(pickup_area_size)
    
    # physics managed by the server
    set_physics_process(false)

func set_picked():
    print(self.to_string() + " has been picked up")
    mode = RigidBody.MODE_STATIC
    state = OBJECT_STATE.picked

func set_released():
    print(self.to_string() + " has been released")
    state = OBJECT_STATE.resting
    mode = RigidBody.MODE_RIGID
    sleeping = false

puppet func set_puppet_transform(global_transform):
    self.global_transform = global_transform

        
func on_highlight_clicked():

    local_player.pickup_object(self)
   
func _process(_delta):

    if !pickable:
        return

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

func _physics_process(_delta):
    
    # this code should *only* be called by the server (where the physics is executed)
    assert(GameState.mode == GameState.SERVER || GameState.mode == GameState.STANDALONE)
    if GameState.mode == GameState.SERVER:
        assert(is_network_master())
        
        if self.state != OBJECT_STATE.picked:
            # if the object has moved, update all the puppets
            if prev_transform != global_transform:
                rpc_unreliable("set_puppet_transform", global_transform)
                prev_transform = global_transform
