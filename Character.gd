extends CharacterBody3D
class_name Character

@onready var anim_player = $AnimationPlayer

# reference to the active player owns by this network peer
# used to ensure the speech bubbles of the other players
# are oriented to face this player
var local_player
var expression = 0 #to export the expression 
@onready var speech_bubble = $SpeechBubbleHandle/SpeechBubble
@onready var speech_bubble_handle = $SpeechBubbleHandle
@onready var face = $Face # used by Robot.gd to compute visibility of players

var username = "Unknown player"
@export var max_earshot_distance: float = 3
@export var max_background_distance: float = 1
@export var neutral_skin: Texture2D

var is_looking_at_player
var dialogue_is_finished
var response
enum state {WAITING_FOR_ANSWER, ANSWER_RECIEVED}

# emitted when this character says something within Player's range
signal player_msg


var quaternion_slerp_progress = 0
var original_orientation
var target_quaternion

var last_location
var total_delta = 0.0
var anim_to_play = "Idle"
var current_anim

var pickedup_object_original_parent
var pickedup_object

const EPSILON = 0.01
const EPSILON_SQUARED = EPSILON * EPSILON

var is_portrait_mode

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	
	$Root/Skeleton3D/Character.set_surface_override_material(0, $Root/Skeleton3D/Character.get_surface_override_material(0).duplicate())
	set_skin(neutral_skin)
	
	local_player = $FakePlayer

	last_location = global_transform.origin

	original_orientation = Quaternion(transform.basis.orthonormalized())
	set_expression(GameState.Expressions.NEUTRAL)
	
	# flip the tip of the speech bubble to place the speech bubble on the left of NPCs
	speech_bubble.flip_left()
	
	# by default, disable camera + light
	portrait_mode(false)
	
	# physics calculation disabled by default
	# will be re-enabled on the server only when the character is
	# created
	set_physics_process(false)
	
	#say("My name is " + username)


# gaze control does not work due to animations overriding head pose    
#puppet func set_puppet_transform(puppet_transform, eye_target):
#    # eye_target is a (x,y,z) point (in world coordinates) that the player
#    # is looking at
#
#    transform = puppet_transform
#
#    var tr = $Root/Skeleton.get_bone_pose(17)
#    $Root/Skeleton.set_bone_pose(17, 
#                                 Transform(face(eye_target), tr.origin))

func enable_collisions(val=true):
	$CollisionShape3D.disabled = !val
	
func portrait_mode(mode):
	
	is_portrait_mode = mode
	
	if mode == true:
		
		$FakePlayer/Camera3D.visible = true
		$OmniLight3D.visible = true
		
		anim_player.current_animation = "Idle"
		anim_player.seek(randf() * anim_player.current_animation_length)
		anim_player.play()
		
		$NameHandle/Name.visible = false

	
	else:
		$FakePlayer/Camera3D.visible = false
		$OmniLight3D.visible = false

func set_portrait_camera():
	$FakePlayer/Camera3D.current = true
func set_close_up_camera():
	$"FakePlayer/Camera3D-closeup".current = true
	
# used to test in Game whether an object colliding with the ray cast for visibility testing
# is indeed a character (via .has_method(i_am_a_character))
func i_am_a_character():
	pass
	

	
@rpc func set_puppet_transform(puppet_transform):

	transform = puppet_transform

@rpc func puppet_set_expression(expr):
	set_expression(expr)

@rpc func puppet_update_players_in_range(in_range, not_in_range):
	# do nothing on the characters, only the Player need to update the UI
	pass
		
	
# this code is only supposed to be called on the server, where the physics takes place
@rpc("any_peer") func execute_set_rotation(angle):
	assert(get_tree().is_server())
	rotate_y(angle)
	#TODO: port to Godot4
	#rpc_unreliable("set_puppet_transform", transform)
	assert(false, "not ported yet to Godot4")
	
@rpc("any_peer") func pickup_object(object_path):

	var object = get_node(object_path)

	pickedup_object = object
	
	pickedup_object_original_parent = object.get_parent()
	pickedup_object_original_parent.remove_child(object)
	
	
	$PickupAnchor.add_child(object)
	object.set_picked()
	
	object.transform = Transform3D() # set the object transform to 0 -> origin matches the anchor point
	
@rpc("any_peer") func release_object():
	
	if pickedup_object:
		
		$PickupAnchor.remove_child(pickedup_object)
		pickedup_object_original_parent.add_child(pickedup_object)
		pickedup_object.set_global_transform($PickupAnchor.get_global_transform())
		pickedup_object.set_released()
		pickedup_object = null
		
################################################################################
#
# these methods are only executed on the server, where the physics takes place
#
@rpc("any_peer") func execute_move_and_slide(linear_velocity):

	assert(get_tree().is_server())
	velocity = linear_velocity
	
@rpc("any_peer") func execute_puppet_says(msg):
	assert(get_tree().is_server())
	rpc("puppet_says", msg)
	
	# execute it as well on the server, for debugging purpose + to track when the players are
	# speaking in the logs
	say(msg)

@rpc func puppet_says(msg):
	print("Got something to say: " + msg)
	
	if local_player.is_in_range(self):
		say(msg)
		
		# connected to the Chat interface in Game.gd
		emit_signal("player_msg", msg, username, false)
		
@rpc("any_peer") func execute_puppet_typing():
	assert(get_tree().is_server())
	rpc("puppet_typing")
	typing()

@rpc func puppet_typing():

	if local_player.is_in_range(self):
		typing()

@rpc("any_peer") func execute_puppet_not_typing_anymore():
	assert(get_tree().is_server())
	rpc("puppet_not_typing_anymore")
	not_typing_anymore()

@rpc func puppet_not_typing_anymore():

	if local_player.is_in_range(self):
		not_typing_anymore()
		
@rpc("any_peer") func execute_puppet_set_expression(msg):
	expression = msg
	assert(get_tree().is_server())
	rpc("puppet_set_expression", msg)
###############################################################################

# physics process is only enabled on the server
func _physics_process(delta):
	
	velocity.y += GameState.GRAVITY * delta
  
	set_velocity(velocity)
	set_up_direction(Vector3.UP)
	move_and_slide()
	
	
	
	
	if velocity.length_squared() > EPSILON_SQUARED:
		# the server is responsible to broadcast the position of all the player
		# once the physics is computed
		
		#TODO: port to Godot4
		#rpc_unreliable("set_puppet_transform", transform)
		assert(false, "not ported yet to Godot4")
	
	
func _process(delta):
	
	
	
	# we buffer a bit as the peer main loop might run faster
	# that the pace at which puppet controller sends position
	# updates. By waiting ~0.1s, we make sure the character would have moved,
	# hence properly setting the animation
	total_delta += delta
	
	if total_delta > 0.1:
		total_delta = 0
		
		if global_transform.origin.distance_squared_to(last_location) > 0.001:
			anim_to_play = "Walk"
		else:
			anim_to_play = "Idle"
			
		current_anim = anim_player.get_current_animation()
		
		if current_anim != anim_to_play:
			anim_player.play(anim_to_play)
	
		last_location = global_transform.origin

	if is_portrait_mode:
		return
		
	# manage speech bubble, incl updating scale and orientation based on
	# player distance
	var dist = distance_to(local_player)
	$SpeechBubbleAnchorAxis.rotation.y = -rotation.y + local_player.camera.get_global_transform().basis.get_euler().y
			
	if speech_bubble.is_speaking:

		var screenPos = local_player.camera.unproject_position($SpeechBubbleAnchorAxis/SpeechBubbleAnchor.get_global_transform().origin)
		speech_bubble_handle.position = screenPos

		# Scale the speech bubble based on distance to player
		var bubble_scale = max(0.5, min(2, 1 / dist))
		speech_bubble_handle.scale = Vector2(bubble_scale, bubble_scale)

	if dist < 10:
		$NameHandle.visible = true
		var screenPos = local_player.camera.unproject_position($SpeechBubbleAnchorAxis/NameAnchor.get_global_transform().origin)
		$NameHandle.position = screenPos

		var name_scale = max(0.5, min(2, 1 / dist))
		$NameHandle.scale = Vector2(name_scale, name_scale)
	else:
		$NameHandle.visible = false
		


	
#######################################################

func is_speaking():
	return speech_bubble.is_speaking

func get_look_at_transform_basis(target,
								 eye = self.transform.origin,
								 up = Vector3(0,1,0)):
	# reimplemented from Godot's source at core/math/transform.cpp
	# to enable Tweening + +Z forward
	
	#var v_z = -(eye - target.get_global_transform().origin)
	var v_z = -(eye - target)
	v_z = v_z.normalized()
	var v_y = up
	var v_x = v_y.cross(v_z)
	
	v_y = v_z.cross(v_x)
	
	v_x = v_x.normalized()
	v_y = v_y.normalized()
	
	return Transform3D(v_x, v_y, v_z, eye).basis

func set_base_skin(resource_path):
	neutral_skin = load(resource_path)
	set_skin(neutral_skin)
	
func set_skin(texture):
	$Root/Skeleton3D/Character.get_surface_override_material(0).albedo_texture = texture
	
func set_username(name):
	username = name
	$NameHandle/Name.text = name
	
	
func set_expression(expr):
	var texture_basename = neutral_skin.resource_path.split("neutral")[0]
	
	var skin
	
	match expr:
		GameState.Expressions.NEUTRAL:
			skin = load(texture_basename + "neutral.png")
			
		GameState.Expressions.ANGRY:
			skin = load(texture_basename + "angry.png")
			
		GameState.Expressions.HAPPY:
			skin = load(texture_basename + "happy.png")
			
		GameState.Expressions.SAD:
			skin = load(texture_basename + "sad.png")
			
			
	$Root/Skeleton3D/Character.get_surface_override_material(0).albedo_texture = skin
	
	
#func face(object):
#
#    target_quaternion = Quat(get_look_at_transform_basis(object))
#                                #$Root/Skeleton.get_bone_pose(17).origin))
#    return target_quaternion
#

func on_rotation_finished():
	target_quaternion = null
	quaternion_slerp_progress = 0
	
func say(text):
	speech_bubble.say(text, speech_bubble.ButtonType.NONE)

func typing():
	speech_bubble.typing()
	
func not_typing_anymore():
	speech_bubble.maskaway()
	
func distance_to(object):
	return get_global_transform().origin.distance_to(object.get_global_transform().origin)

func quaternions_distance(q1, q2):
	# -> 0 if same orientation, -> 1 if 180deg apart
	# based on https://math.stackexchange.com/a/90098
	var dist = 1 - pow(q1.dot(q2), 2)
	#print(dist)
	
	return dist

	
#func _physics_process(delta):
#    
#    if target_quaternion:
#
#        var current_quaternion = Quat(transform.basis)
#
#        if quaternions_distance(current_quaternion, target_quaternion) > 0.1 or $RotationTween.is_active():
#            # large rotation? interpolate!
#
#            if not $RotationTween.is_active():
#                $RotationTween.interpolate_property(self, "quaternion_slerp_progress", 0, 1, 2, Tween.TRANS_LINEAR, Tween.EASE_IN)
#                $RotationTween.connect("tween_all_completed", self, "on_rotation_finished")
#                $RotationTween.start()
#
#            set_transform(Transform(current_quaternion.slerp(target_quaternion, quaternion_slerp_progress), transform.origin))
#
#        else:
#            # small rotation? set it directly
#            set_transform(Transform(target_quaternion, transform.origin))
#            target_quaternion = null
#
#            ## FOR HEAD-ONLY ROTATION
#            #var tr = $Root/Skeleton.get_bone_pose(17)
#            #$Root/Skeleton.set_bone_pose(17, 
#            #                        Transform(Quat(tr.basis).slerp(target_quaternion, quaternion_slerp_progress),
#            #                                  tr.origin))
#
#
#
