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
const MAX_SLOPE_ANGLE = 40

onready var camera = $Rotation_helper/Camera
onready var rotation_helper = $Rotation_helper

signal spoke
#signal done_speaking

# each time I meet a new NPC, I add it to this list
var known_npc = []

var MOUSE_SENSITIVITY = 0.1

func _ready():

    #Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    

func _physics_process(delta):
    
    process_input(delta)
    process_movement(delta)
    
    
    rpc_unreliable("set_puppet_transform", transform)
    
    # version that also communicate the gaze direction -- not working because
    # puppet head pose overridden by animation
    #rpc_unreliable("set_puppet_transform", transform, $Rotation_helper/CameraTarget.get_global_transform().origin)

# connect to the UI 'on_chat_msg' signal by Game.gd
func say(msg):
    rpc("puppet_says", msg)
    
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
        #input_movement_vector.x -= 1
        self.rotate_y(deg2rad(1))
    if Input.is_action_pressed("ui_right"):
        #input_movement_vector.x += 1
        self.rotate_y(deg2rad(-1))

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

    vel.y += delta * GRAVITY

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
    vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))

func _input(event):
    
    if event is InputEventMouseMotion: # and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY))
        self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))

        var camera_rot = rotation_helper.rotation_degrees
        camera_rot.x = clamp(camera_rot.x, -20, 30)
        rotation_helper.rotation_degrees = camera_rot



func has_met(character):
    return (character in known_npc)

func meet(character):
    known_npc.append(character)


