extends CharacterBody3D

signal destination_reached

enum State {IDLE, WALKING}
@export var state: State = State.IDLE

@export var nav_targets: Array[Node3D]
@export var random_target_order: bool = true
var last_nav_target_idx: int = 0

var nav_was_active: bool = false

# enum value must correspond to the name of the corresponding mesh
enum CharacterType {
Boss_Female_01,
Boss_Male_01,
Business_Female_01,
Business_Female_02,
Business_Female_03,
Business_Female_04,
Business_Male_01,
Business_Male_02,
Business_Male_03,
Business_Male_04,
Cleaner_Female_01,
Cleaner_Male_01,
Developer_Female_01,
Developer_Female_02,
Developer_Male_01,
Developer_Male_02,
Security_Female_01,
Security_Male_01,
}
@export var character: CharacterType = CharacterType.Boss_Female_01

var last_global_position: Vector3

const EPSILON = 0.01
const SPEED = 1.9

const ANIMATIONS = {
	State.IDLE: "animations-walks/idle",
	State.WALKING: "animations-walks/std_walk",
}

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

func _ready():
	randomize()
	
	for m in $Model/Skeleton3D.get_children():
		m.visible = false
	$Model/Skeleton3D.get_node(CharacterType.keys()[character]).visible = true
	
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	
	destination_reached.connect(set_next_target)

	# Make sure to not await during _ready.
	call_deferred("actor_setup")
	update_animation()
	
func update_animation():
	$AnimationPlayer.play(ANIMATIONS[state])
	
func actor_setup():
		
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame

	last_global_position = global_position
	
	# Now that the navigation map is no longer empty, set the movement target.
	

func get_next_target():
	
	if nav_targets.size() == 1:
		return nav_targets[0]
	
	var idx = last_nav_target_idx
		
	if random_target_order:		
		while idx == last_nav_target_idx:
			idx = randi() % nav_targets.size()
	else:
		idx = (idx + 1) % nav_targets.size()
	
	last_nav_target_idx = idx
	return nav_targets[idx]
	
func set_next_target():
	
	# already in pause, no need to schedule yet another next nav target
	if state == State.IDLE:
		return
		
	state = State.IDLE
	update_animation()
	await get_tree().create_timer(randi() % 3 + 1).timeout
	
	state = State.WALKING
	update_animation()
	
	var next_target = get_next_target()
	#print(name + ": Setting next target to #" + next_target.name)
	set_target(next_target.global_position)
	nav_was_active = true
	
func set_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)

func _physics_process(delta):

	if state == State.IDLE:
		return
		
	if nav_was_active and navigation_agent.is_navigation_finished():
		nav_was_active = false
		#print(name + ": reached destination")
		destination_reached.emit()
		return
	
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	# hack to ensure the agent does not float in the air
	next_path_position.y = 0

	var current_agent_position: Vector3 = global_position
	var new_velocity: Vector3 = (next_path_position - current_agent_position).normalized() * SPEED

	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)
		
	
func _on_velocity_computed(safe_velocity: Vector3) -> void:

	velocity = safe_velocity
	move_and_slide()
	
	# character stuck somewhere! choose another target
	if (global_position - last_global_position).length() < EPSILON:
		set_next_target()
		
	if (global_position - last_global_position).length() > EPSILON:
		if state != State.WALKING:
			state = State.WALKING
			update_animation()
	
		
		look_at(global_position + safe_velocity, Vector3(0, 1, 0), true)
	
	last_global_position = global_position
