extends CharacterBody3D
var player = null
@export var player_path : NodePath
@onready var nav_agent = $NavigationAgent3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
func _ready():
	player = get_node(player_path)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	velocity = Vector3.ZERO
	nav_agent.set_target_position(player.global_transform.origin)
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_transform.origin).normalized()*SPEED
	if false:
		velocity.y = JUMP_VELOCITY

	
	move_and_slide()
