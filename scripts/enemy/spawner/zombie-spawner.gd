extends Node3D
@export_group("zombie")
@export var spawnable: PackedScene
@export var spawn_count := 1
@export var spawn_radius:= 5
@export var speed:= 3.0
@export var anim_speed_scale := 0.5
@export var player_dist_max := 50
@export var origin_dist_max := 20
var player = null
var rng = RandomNumberGenerator.new()
@export_group("player")
@export var player_path : NodePath
var zombies = []

func _ready() -> void:
	add_to_group("zombie_spawner")
	player = get_node(player_path)
	for i in spawn_count:
		spawn_zombie()

func spawn_zombie():
	var newzombie = spawnable.instantiate()
	add_child(newzombie)
	var randx = rng.randf_range(global_position.x - spawn_radius, global_position.x + spawn_radius)
	var randz = rng.randf_range(global_position.z - spawn_radius, global_position.z + spawn_radius)

	# Raycast down to find ground
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		Vector3(randx, global_position.y + 50, randz),
		Vector3(randx, global_position.y - 50, randz)
	)
	var result = space.intersect_ray(query)
	var spawn_y = global_position.y
	if result:
		spawn_y = result.position.y + 0.5

	newzombie.global_position = Vector3(randx, spawn_y, randz)
	newzombie.player_path = player_path
	newzombie.player = get_node(player_path)
	newzombie.SPEED = speed
	newzombie.anim_speed_scale = anim_speed_scale
	newzombie.player_dist_max = player_dist_max
	newzombie.origin_dist_max = origin_dist_max
	zombies.append(newzombie)

func reset():
	for zombie in zombies:
		if is_instance_valid(zombie):
			zombie.queue_free()
	zombies.clear()
	for i in spawn_count:
		spawn_zombie()

func _process(_delta: float) -> void:
	pass
	#if len(zombies) < 3:
		#spawn_zombie()

func _on_player_3d_player_death() -> void:
	pass
