extends KinematicBody

# mouselook + motion based on godot FPS tutorial:
# https://docs.godotengine.org/en/stable/tutorials/3d/fps_tutorial/part_one.html
var score=0
var vel = Vector3.ZERO
var prev_vel = Vector3.ZERO

const MAX_SPEED = 4.5#1.5
const JUMP_SPEED = 5
const ACCEL = 2.5

var dir = Vector3()

const DEACCEL= 16

var players_in_range = []
signal player_list_updated

var pickedup_object_original_parent
var pickedup_object

onready var camera = $Rotation_helper/Camera
onready var rotation_helper = $Rotation_helper

var MOUSE_SENSITIVITY = 0.1


func _ready():

    #Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    
func toggle_collisions(enabled=true):
    $CollisionShape.disabled = !enabled

puppet func set_puppet_transform(puppet_transform):

    transform = puppet_transform
    
func _physics_process(delta):
    
    process_input(delta)
    process_movement(delta)
    
    # version that also communicate the gaze direction -- not working because
    # puppet head pose overridden by animation
    #rpc_unreliable("set_puppet_transform", transform, $Rotation_helper/CameraTarget.get_global_transform().origin)

puppet func puppet_says(_msg):
    # do nothing on the player itself! (but the other players, eg, the Characters will display the speech bubble)
    pass

puppet func puppet_set_expression(_msg):
    # do nothing on the player itself! (but the other players, eg, the Characters will display the right expression)
    pass

puppet func puppet_update_players_in_range(in_range, not_in_range):
    
    if in_range.empty() and not_in_range.empty():
        return
    
    for id in in_range:
        var player = get_node("/root/Game/Players/" + id)
        players_in_range.append(player)
    for id in not_in_range:
        var player = get_node("/root/Game/Players/" + id)
        players_in_range.erase(player)
    
    # connected to Chat UI in Game.gd
    emit_signal("player_list_updated", players_in_range)

func is_in_range(player):
    return player in players_in_range
    
# connect to the Chat UI 'on_chat_msg' signal in Game.gd
func say(msg):
    rpc_id(1, "execute_puppet_says", msg)

# connect to the Chat UI 'on_chat_msg' signal in Game.gd
func typing():
    rpc_id(1, "execute_puppet_typing")

puppet func puppet_typing():
    # do nothing on the player itself! (but the other players, eg, the Characters will display the speech bubble)
    pass

# connect to the Chat UI 'on_chat_msg' signal in Game.gd
func not_typing_anymore():
    rpc_id(1, "execute_puppet_not_typing_anymore")

puppet func puppet_not_typing_anymore():
    # do nothing on the player itself! (but the other players, eg, the Characters will display the speech bubble)
    pass

# connect to the UI 'on_set_expr' signal in Game.gd
func set_expression(expr):
    
    rpc_id(1, "execute_puppet_set_expression", expr)

func pickup_object(object):
    
    
    # already holding an object?
    if pickedup_object:
        return

    
    rpc("pickup_object", str(object.get_path()))
    
    pickedup_object = object
    
    pickedup_object_original_parent = object.get_parent()
    pickedup_object_original_parent.remove_child(object)
    
    $Rotation_helper/Camera/PickupAnchor.add_child(object)
    object.set_picked()
    
    object.transform = Transform() # set the object transform to 0 -> origin matches the anchor point


func release_object():
    
    if pickedup_object:
        rpc("release_object")
        
        $Rotation_helper/Camera/PickupAnchor.remove_child(pickedup_object)
        pickedup_object_original_parent.add_child(pickedup_object)
        pickedup_object.set_global_transform($Rotation_helper/Camera/PickupAnchor.get_global_transform())
        pickedup_object.set_released()
        pickedup_object = null

# returns true if the player is facing 'point' (in global coordinates)
func is_facing(point):
    var local_point = point - global_transform.origin
    var gaze = Vector3(0,0,1).rotated(Vector3(0,1,0), rotation.y)
    return local_point.dot(gaze) > 0
    

func process_input(_delta):

    # ----------------------------------
    # Walking
    dir = Vector3()
    var cam_xform = camera.get_global_transform()

    var input_movement_vector = Vector2()

    if Input.is_action_pressed("ui_up"):
        input_movement_vector.y += 1
    if Input.is_action_pressed("ui_down"):
        input_movement_vector.y -= 1
    if Input.is_action_pressed("ui_left"):
        input_movement_vector.x -= 1
        #self.rotate_y(deg2rad(1))
    if Input.is_action_pressed("ui_right"):
        input_movement_vector.x += 1
        #self.rotate_y(deg2rad(-1))

    input_movement_vector = input_movement_vector.normalized()

    # Basis vectors are already normalized.
    dir += -cam_xform.basis.z * input_movement_vector.y
    dir += cam_xform.basis.x * input_movement_vector.x

    # ----------------------------------

    # ----------------------------------
    # Jumping
    if is_on_floor():
        if Input.is_action_just_pressed("ui_jump"):
            vel.y = JUMP_SPEED
    # ----------------------------------

func process_movement(delta):
    dir.y = 0
    dir = dir.normalized()

    vel.y = 0 # -> gravity managed by the server in Character._process_physics

    var hvel = vel
    hvel.y = 0

    var target = dir
    target *= MAX_SPEED

    var accel
    if dir.dot(hvel) > 0:
        accel = ACCEL
    else:
        accel = DEACCEL

    hvel = hvel.linear_interpolate(target, accel * delta)
    vel.x = hvel.x
    vel.z = hvel.z
    
    if vel != prev_vel:
        if GameState.mode == GameState.CLIENT:
            # execute the actual motion on the server, so that physics are computed
            # the resulting new position will be updated by the server via 'set_puppet_transform'
            rpc_unreliable_id(1, "execute_move_and_slide", vel)
        elif GameState.mode == GameState.STANDALONE:
            vel.y += GameState.GRAVITY * delta
            vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, GameState.MAX_SLOPE_ANGLE)
        else:
            assert(false)
    
    prev_vel = vel

func _input(event):
    
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY))
        
        if GameState.mode == GameState.CLIENT:
            rpc_unreliable_id(1, "execute_set_rotation", deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))
        elif GameState.mode == GameState.STANDALONE:
            self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))
        else:
            assert(false)
            
        var camera_rot = rotation_helper.rotation_degrees
        camera_rot.x = clamp(camera_rot.x, -20, 30)
        rotation_helper.rotation_degrees = camera_rot
        

    # trying to workaround HTML5 security:
    # MOUSE_MODE_CAPTURED can *only* take place during an 'actual' event (eg
    # a click, but not a motion)
    # Therefore, if waiting *one frame* to change to mouselook (as done for non-HTML5
    # platform), the mouselook won't trigger as it will take place during a 'mouse motion'
    # event.
    #
    # The original reason for waiting one frame is to ensure the click events are
    # properly register, eg to pickup objects. However, it seems to work in HTML5
    # without waiting...
    if OS.get_name() == "HTML5":
        if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED and \
        Input.is_action_pressed("mouselook"):
                print("Capturing mouse")
                Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    else:
        if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED and \
        not Input.is_action_just_pressed("mouselook") and \
        Input.is_action_pressed("mouselook"):
                print("Capturing mouse")
                Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

    if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and \
       event.is_action_released("mouselook"):
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
            release_object()

