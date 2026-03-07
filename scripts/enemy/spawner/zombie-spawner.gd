extends Node3D

@export_group("zombie")
@export var spawnable: PackedScene
@export var spawn_radius:= 5
@export var speed:= 3
@export var player_dist_max := 50
@export var origin_dist_max := 20
var player = null
var rng = RandomNumberGenerator.new()
@export_group("player")
@export var player_path : NodePath
var zombies = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_node(player_path)
	spawn_zombie()

func spawn_zombie():
	var newzombie = spawnable.instantiate()
	add_child(newzombie)
	var randx = rng.randf_range(position.x-spawn_radius,position.x+spawn_radius)
	var randz = rng.randf_range(position.z-spawn_radius,position.z+spawn_radius)
	newzombie.position = Vector3(randx,position.y,randz)
	newzombie.player_path = player_path
	newzombie.player = get_node(player_path)
	newzombie.SPEED = speed
	newzombie.player_dist_max = player_dist_max
	newzombie.origin_dist_max = origin_dist_max
	zombies.append(newzombie)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if len(zombies) < 3:
		spawn_zombie()
