extends CharacterBody3D
var player = null
@export var player_path : NodePath
@onready var nav_agent = $NavigationAgent3D
@export var player_dist_max: float
var origin: Vector3
@export var SPEED = 3.0
@export var JUMP_VELOCITY = 4.5
func _ready():
	player = get_node(player_path)
	origin = self.global_position

func _physics_process(delta: float) -> void:
	# Add the gravity.
	var player_dist = global_position.distance_to(player.global_position)
	velocity = Vector3.ZERO
	var spd = SPEED
	if player_dist < player_dist_max:
		nav_agent.set_target_position(player.global_transform.origin)
	else:
		nav_agent.set_target_position(self.origin)
		spd = spd +10
	
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_transform.origin).normalized()*spd
	if false:
		velocity.y = JUMP_VELOCITY

	
	move_and_slide()
