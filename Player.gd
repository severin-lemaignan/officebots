extends KinematicBody2D

var velocity
var speed = 200

    
func get_input():
    velocity = Vector2()
    if Input.is_action_pressed('ui_right'):
        velocity.x += 1
    if Input.is_action_pressed('ui_left'):
        velocity.x -= 1
    if Input.is_action_pressed('ui_down'):
        velocity.y += 1
    if Input.is_action_pressed('ui_up'):
        velocity.y -= 1
    velocity = velocity.normalized() * speed

puppet func set_puppet_position(puppet_position):
    position = puppet_position
    
func _physics_process(delta):

    if is_network_master():
        get_input()
        velocity = move_and_slide(velocity)
        
        print(velocity)
        rpc_unreliable("set_puppet_position", position)
