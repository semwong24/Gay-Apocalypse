extends Node3D
@export var spawnable: PackedScene
@export var radius:float
@export var speed: float
var player = null
var rng = RandomNumberGenerator.new()
@export var player_path : NodePath
var zombies = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_node(player_path)
	spawn_zombie()

func spawn_zombie():
	var newzombie = spawnable.instantiate()
	add_child(newzombie)
	var randx = rng.randf_range(position.x-radius,position.x+radius)
	var randz = rng.randf_range(position.z-radius,position.z+radius)
	newzombie.position = Vector3(randx,position.y,randz)
	newzombie.player_path = player_path
	newzombie.player = get_node(player_path)
	newzombie.SPEED = speed
	zombies.append(newzombie)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if len(zombies) < 3:
		spawn_zombie()
