extends CharacterBody3D
var player = null
@export_group("player info")
@export var player_path : NodePath
@onready var nav_agent = $NavigationAgent3D
@onready var audio_player = $groaner
@onready var anim = $"zomb walk/AnimationPlayer"
@export var player_dist_max := 50
@export_group("zombie traits")
@export var origin_dist_max := 20
var origin: Vector3
@export var SPEED := 1.5
@export var JUMP_VELOCITY := 4.5
@export var anim_speed_scale := 0.5
var rng = RandomNumberGenerator.new()
var randomtick = 0
var randompick = 0
var sureok = false
var walkanimfin = false
var sounds = []
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	add_to_group("zombie")
	player = get_node(player_path)
	origin = self.global_position
	sounds.append(preload("res://assets/sfx/adjustedvolume/zombie-groan-0.wav"))
	sounds.append(preload("res://assets/sfx/adjustedvolume/zombie-groan-1.wav"))
	sounds.append(preload("res://assets/sfx/adjustedvolume/zombie-groan-2.wav"))
	audio_player.stream=sounds.front()
	audio_player.play()
	anim.play("walk")

func _physics_process(delta: float) -> void:
	randomtick += delta
	var player_dist = global_position.distance_to(player.global_position)
	var origin_dist = global_position.distance_to(origin)
	var spd = SPEED

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	if sureok and randomtick >= randompick/4:
		sureok = false
		randomtick = 0
		randomize_sounds(sounds)
		randompick = rng.randi_range(0,30)

	if player_dist < player_dist_max:
		nav_agent.set_target_position(player.global_transform.origin)
	else:
		if origin_dist < origin_dist_max:
			if randomtick>=randompick:
				var randx = rng.randf_range(origin.x-origin_dist_max,origin.x+origin_dist_max)
				var randz = rng.randf_range(origin.z-origin_dist_max,origin.z+origin_dist_max)
				nav_agent.set_target_position(Vector3(randx,position.y,randz))
				randompick = rng.randi_range(0,30)
		else:
			nav_agent.set_target_position(self.origin)

	var next_nav_point = nav_agent.get_next_path_position()
	var nav_velocity = (next_nav_point - global_transform.origin).normalized() * spd

	var separation = Vector3.ZERO
	for zombie in get_tree().get_nodes_in_group("zombie"):
		if zombie == self:
			continue
		var dist = global_position.distance_to(zombie.global_position)
		if dist < 1.5 and dist > 0.01:
			separation += (global_position - zombie.global_position).normalized() / dist

	velocity.x = nav_velocity.x + separation.x * 2.0
	velocity.z = nav_velocity.z + separation.z * 2.0

	if false:
		velocity.y = JUMP_VELOCITY

	move_and_slide()

	var flat_velocity = Vector3(velocity.x, 0, velocity.z)
	if flat_velocity.length() > 0.1:
		look_at(global_position + flat_velocity, Vector3.UP)

	anim.speed_scale = anim_speed_scale

func randomize_sounds(s:Array) -> void:
	s.shuffle()
	audio_player.stream = sounds.front()
	audio_player.play()

func die():
	queue_free()

func _on_groaner_finished() -> void:
	sureok = true

func _on_walk_animation_finished(anim_name: StringName) -> void:
	walkanimfin = true
	anim.play("walk")
	walkanimfin = false
	pass
