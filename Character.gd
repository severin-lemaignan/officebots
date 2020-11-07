extends StaticBody
class_name Character

onready var anim_player = $AnimationPlayer

onready var speech_bubble = $SpeechBubbleHandle/SpeechBubble
onready var speech_bubble_handle = $SpeechBubbleHandle

export(String) var username = "Character"
export(float) var max_earshot_distance = 3
export(float) var max_background_distance = 1
export(Texture) var neutral_skin

enum Expressions {NEUTRAL, ANGRY, HAPPY, SAD}
export(Expressions) var expression setget set_expression

var is_speaking
var is_looking_at_player
var dialogue_is_finished
var response
enum state {WAITING_FOR_ANSWER, ANSWER_RECIEVED}

var quaternion_slerp_progress = 0
var original_orientation
var target_quaternion

#var npcs = get_tree().get_root().get_node("Game/NPCs")

signal ready_to_speak

var last_location
var total_delta = 0.0
var anim_to_play = "Idle"
var current_anim

# Called when the node enters the scene tree for the first time.
func _ready():
#    set_fixed_process(true)
#    player.connect("spoke", player, "say()")
    last_location = translation

    original_orientation = Quat(transform.basis.orthonormalized())
    set_expression(Expressions.NEUTRAL)
    
    # flip the tip of the speech bubble to place the speech bubble on the left of NPCs
    speech_bubble.flip_left()
    #say("My name is " + username, 5)
    

# gaze control doe snot work due to animations overriding head pose    
#puppet func set_puppet_transform(puppet_transform, eye_target):
#    # eye_target is a (x,y,z) point (in world coordinates) that the player
#    # is looking at
#
#    transform = puppet_transform
#
#    var tr = $Root/Skeleton.get_bone_pose(17)
#    $Root/Skeleton.set_bone_pose(17, 
#                                 Transform(face(eye_target), tr.origin))

puppet func puppet_says(msg):
    print("Got something to say: " + msg)
    say(msg)
    
puppet func set_puppet_transform(puppet_transform):
    
    transform = puppet_transform
    
func _process(delta):
    
    
    # we buffer a bit as the peer main loop might run faster
    # that the pace at which puppet controller sends position
    # updates. By waiting ~0.1s, we make sure the character would have moved,
    # hence properly setting the animation
    total_delta += delta
    
    if total_delta > 0.1:
        total_delta = 0
        
        if translation.distance_squared_to(last_location) > 0.001:
            anim_to_play = "Walk"
        else:
            anim_to_play = "Idle"
            
        current_anim = anim_player.get_current_animation()
        
        if current_anim != anim_to_play:
            anim_player.play(anim_to_play)
    
        last_location = translation

    
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
    
    return Transform(v_x, v_y, v_z, eye).basis

func set_expression(expression):
    var texture_basename = neutral_skin.resource_path.split("neutral")[0]
    
    var skin
    
    match expression:
        Expressions.NEUTRAL:
            skin = load(texture_basename + "neutral.png")
        Expressions.ANGRY:
            skin = load(texture_basename + "angry.png")
        Expressions.HAPPY:
            skin = load(texture_basename + "happy.png")
        Expressions.SAD:
            skin = load(texture_basename + "sad.png")
            
    $Root/Skeleton/Character.get_surface_material(0).set_shader_param("skin", skin)
    
func face(object):

    target_quaternion = Quat(get_look_at_transform_basis(object))
                                #$Root/Skeleton.get_bone_pose(17).origin))
    return target_quaternion


func on_rotation_finished():
    target_quaternion = null
    quaternion_slerp_progress = 0
    
func say(text, wait_time=2, force=false):
#    $SpeechBubbleHandle/SpeechBubble/speech_bubble/Name.text = username
    
#    emit_signal("spoke")
#    var player2 = get_tree().root.get_node("Game/Player")
    
#    if is_speaking() and not force:
#        return
        
#    var dist = distance_to(player2)
    
    #For background dialogue
#    if force:
#        speech_bubble.say(text, wait_time)
    
    # NPC too far from Player? we don't hear it!
#    if dist > max_earshot_distance:
#        return
    
    speech_bubble.say(text, speech_bubble.ButtonType.NONE, wait_time)

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
#    if speech_bubble.is_speaking:
#
#        var dist = distance_to(player)
#
#
#        var screenPos = player.camera.unproject_position($SpeechBubbleAnchorAxis/SpeechBubbleAnchor.get_global_transform().origin)
#        speech_bubble_handle.position = screenPos
#
#        # Scale the speech bubble based on distance to player
#        var bubble_scale = max(0.5, min(1, 1 / dist))
#        speech_bubble_handle.scale = Vector2(bubble_scale, bubble_scale)
#
#        var s= speech_bubble_handle.scale
#
#    if is_looking_at_player:
#        face(player)
#
#    $SpeechBubbleAnchorAxis.rotation.y = -rotation.y + player.camera.get_global_transform().basis.get_euler().y


