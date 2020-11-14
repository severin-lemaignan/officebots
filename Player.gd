extends KinematicBody

# mouselook + motion based on godot FPS tutorial:
# https://docs.godotengine.org/en/stable/tutorials/3d/fps_tutorial/part_one.html

const GRAVITY = -24.8
var vel = Vector3()
const MAX_SPEED = 1.5
const JUMP_SPEED = 1
const ACCEL = 2.5

var dir = Vector3()

const DEACCEL= 16


onready var camera = $Rotation_helper/Camera
onready var rotation_helper = $Rotation_helper

# each time I meet a new NPC, I add it to this list
var known_npc = []

var MOUSE_SENSITIVITY = 0.1

var pickedup_object_original_parent
var pickedup_object

func _ready():

    #Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    

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
    
# connect to the UI 'on_chat_msg' signal by Game.gd
func say(msg):
    rpc_id(1, "execute_puppet_says", msg)

func pickup_object(object):
    
    pickedup_object = object
    
    pickedup_object_original_parent = object.get_parent()
    pickedup_object_original_parent.remove_child(object)
    
    
    $Rotation_helper/Camera/PickupAnchor.add_child(object)
    object.mode = RigidBody.MODE_STATIC
    
    object.transform = Transform() # set the object transform to 0 -> origin matches the anchor point

func release_object():
    if pickedup_object:
        
        $Rotation_helper/Camera/PickupAnchor.remove_child(pickedup_object)
        pickedup_object_original_parent.add_child(pickedup_object)
        
        pickedup_object.set_global_transform($Rotation_helper/Camera/PickupAnchor.get_global_transform())
        
        pickedup_object.mode = RigidBody.MODE_RIGID
        pickedup_object.sleeping = false
        
        pickedup_object = null
        
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

    # ----------------------------------
    # Capturing/Freeing the cursor
    if Input.is_action_just_pressed("ui_capture_mouse"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    # ----------------------------------

func process_movement(delta):
    dir.y = 0
    dir = dir.normalized()

    #vel.y += delta * GRAVITY
    vel.y = 0

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
    
    if vel:
    # execute the actual motion on the server, so that physics are computed
    # the resulting new position will be updated by the server via 'set_puppet_transform'
        rpc_unreliable_id(1, "execute_move_and_slide", vel)

func _input(event):
    
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY))
        #self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))
        rpc_unreliable_id(1, "execute_set_rotation", deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))
        
        var camera_rot = rotation_helper.rotation_degrees
        camera_rot.x = clamp(camera_rot.x, -20, 30)
        rotation_helper.rotation_degrees = camera_rot
        

    if not Input.is_action_just_pressed("mouselook") and Input.is_action_pressed("mouselook"):
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

    if event.is_action_released("mouselook"):
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        release_object()

