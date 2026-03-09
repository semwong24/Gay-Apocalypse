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
var rng = RandomNumberGenerator.new()
var randomtick = 0
var randompick = 0
var sureok = false
var walkanimfin = false
var sounds = []
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
func _ready():
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
	velocity = Vector3.ZERO
	var spd = SPEED
	if sureok and randomtick >= randompick/4:
		sureok = false
		randomtick = 0
		randomize_sounds(sounds)
		randompick = rng.randi_range(0,30)
	if player_dist < player_dist_max:
		nav_agent.set_target_position(player.global_transform.origin)
	else:
		if origin_dist < origin_dist_max:
			spd = spd *0.75
			if randomtick>=randompick:
				var randx = rng.randf_range(origin.x-origin_dist_max,origin.x+origin_dist_max)
				var randz = rng.randf_range(origin.z-origin_dist_max,origin.z+origin_dist_max)
				nav_agent.set_target_position(Vector3(randx,position.y,randz))
				randompick = rng.randi_range(0,30)
		else:
			nav_agent.set_target_position(self.origin)
			spd = spd *5
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_transform.origin).normalized()*spd
	if false:
		velocity.y = JUMP_VELOCITY

	
	move_and_slide()
	look_at(global_position + velocity, Vector3.UP)
	anim.speed_scale = velocity.length()/SPEED
func randomize_sounds(s:Array) -> void:
	s.shuffle()
	audio_player.stream = sounds.front()
	audio_player.play()	
func die():
	queue_free()


func _on_groaner_finished() -> void:
	sureok = true
	#randomize_sounds(sounds)
	


func _on_walk_animation_finished(anim_name: StringName) -> void:
	walkanimfin = true
	anim.play("walk")
	walkanimfin = false
	pass # Replace with function body.
