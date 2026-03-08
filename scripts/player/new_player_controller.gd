extends CharacterBody3D

@export var speed := 4.0
@export var sprint_speed := 7.0
@export var mouse_sensitivity := 0.2
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var cam: Camera3D
@export var flashlight: SpotLight3D
var alive:=true
@export_group("headbob")
@export var headbob_freq := 2.0
@export var headbob_amplitude := 0.04

@onready var deathscreen: Sprite2D = $deathshow

@export_group("Stamina")
@export var max_stamina := 100.0
@export var stamina_drain_rate := 10.0
@export var stamina_regen_rate := 15.0
@export var stamina_required_to_sprint := 60.0
@export var sprint_cooldown_after_depletion := 1.0
var current_stamina := 100.0
var is_on_sprint_cooldown := false
var cooldown_timer := 0.0

signal sprint_started
signal sprint_stopped
signal player_death

@onready var footstep_player_indoor: AudioStreamPlayer3D = $FootstepPlayerIndoors
@onready var footstep_player_concrete: AudioStreamPlayer3D = $FootstepPlayerConcrete
@onready var footstep_player_terrain: AudioStreamPlayer3D = $FootstepPlayerTerrain
@onready var ambient_wind: AudioStreamPlayer = $AmbientWind
@onready var ambient_crickets: AudioStreamPlayer = $AmbientCrickets

var headbob_time := 0.0
var flashlight_on = false
var is_sprinting = false

var floor_raycast: RayCast3D
var terrain_check_raycast: RayCast3D

var last_floor_type = ""
var floor_type_counter = 0
var pending_floor_type = ""

var is_in_outdoor_area = false

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_process_input(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	flashlight.visible = false
	current_stamina = max_stamina
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(60)
	
	floor_raycast = RayCast3D.new()
	floor_raycast.target_position = Vector3(0, -1.05, 0)
	floor_raycast.enabled = true
	floor_raycast.collide_with_areas = true
	floor_raycast.collide_with_bodies = true
	floor_raycast.hit_from_inside = true
	floor_raycast.set_collision_mask_value(1, true)
	add_child(floor_raycast)

	terrain_check_raycast = RayCast3D.new()
	terrain_check_raycast.target_position = Vector3(0, -1.01, 0)
	terrain_check_raycast.enabled = true
	terrain_check_raycast.collide_with_areas = false
	terrain_check_raycast.collide_with_bodies = true
	terrain_check_raycast.set_collision_mask_value(1, true)
	add_child(terrain_check_raycast)
	
	call_deferred("_connect_to_outdoor_area")

func _connect_to_outdoor_area():
	var outdoor_area = get_tree().get_first_node_in_group("outdoor_area")
	if outdoor_area:
		outdoor_area.body_entered.connect(_on_outdoor_entered)
		outdoor_area.body_exited.connect(_on_outdoor_exited)
		if outdoor_area.overlaps_body(self):
			is_in_outdoor_area = true

func _on_outdoor_entered(body: Node3D) -> void:
	if body == self:
		is_in_outdoor_area = true

func _on_outdoor_exited(body):
	if body == self:
		is_in_outdoor_area = false

func _input(event):
	if GameState.comic_playing or GameState.ui_open:
		return
	
	if get_tree().paused:
		return

	if event.is_action_pressed("skip_dialogue") and Dialogic.current_timeline != null:
		Dialogic.VAR.set("opening_finished", true)
		Dialogic.end_timeline()
			
	if event.is_action_pressed("toggle_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseMotion:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return
		rotate_y(-event.relative.x * mouse_sensitivity / 100.0)
		$Head.rotate_x(-event.relative.y * mouse_sensitivity / 100.0)
		$Head.rotation_degrees.x = clamp($Head.rotation_degrees.x, -89, 89)
		flashlight.rotation = cam.rotation

func _physics_process(delta):
	if GameState.comic_playing or GameState.ui_open:
		return
		
	if Input.is_action_just_pressed("toggle_flashlight") and PlayerInventory.has_flashlight:
		flashlight_on = !flashlight_on
		flashlight.visible = flashlight_on

	if is_on_sprint_cooldown:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			is_on_sprint_cooldown = false
	
	handle_stamina(delta)
	
	var was_sprinting = is_sprinting
	var wants_to_sprint = Input.is_action_pressed("sprint")
	var can_sprint = wants_to_sprint and current_stamina >= stamina_required_to_sprint and not is_on_sprint_cooldown
	
	if is_sprinting:
		if current_stamina < stamina_required_to_sprint or not wants_to_sprint:
			is_sprinting = false
			if current_stamina < stamina_required_to_sprint:
				is_on_sprint_cooldown = true
				cooldown_timer = sprint_cooldown_after_depletion
	else:
		if can_sprint:
			is_sprinting = true
	
	if is_sprinting and not was_sprinting:
		sprint_started.emit()
	elif not is_sprinting and was_sprinting:
		sprint_stopped.emit()
	
	var current_speed = sprint_speed if is_sprinting else speed

	var direction = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_back"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
		
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_normal().y < 0.5 and collision.get_normal().y > -0.1:
			if velocity.length() > 0.1:
				velocity.y = 6.0

	headbob_time += delta * velocity.length() * float(is_on_floor())
	cam.transform.origin = headbob(headbob_time)
	
	handle_footsteps(delta)
	handle_ambient_sound()

func handle_stamina(delta):
	var is_moving = velocity.length() > 0.1
	if is_sprinting and is_moving:
		current_stamina -= stamina_drain_rate * delta
		current_stamina = max(0, current_stamina)
	else:
		current_stamina += stamina_regen_rate * delta
		current_stamina = min(max_stamina, current_stamina)

func handle_ambient_sound():
	if is_in_outdoor_area:
		if ambient_wind and not ambient_wind.playing:
			ambient_wind.play()
		if ambient_crickets and not ambient_crickets.playing:
			ambient_crickets.play()
	else:
		if ambient_wind and ambient_wind.playing:
			ambient_wind.stop()
		if ambient_crickets and ambient_crickets.playing:
			ambient_crickets.stop()

func handle_footsteps(delta):
	if GameState.comic_playing:
		_stop_all_footsteps()
		return
	
	var is_moving = velocity.length() > 0.1
	
	if is_moving:
		var desired_pitch = 1.3 if is_sprinting else 1.0
		var new_floor = ""

		if floor_raycast.is_colliding():
			var collider = floor_raycast.get_collider()
			if terrain_check_raycast.is_colliding():
				var body_collider = terrain_check_raycast.get_collider()
				if body_collider and body_collider.get_class() == "Terrain3D":
					new_floor = "terrain"
				elif collider and collider.is_in_group("concrete_area"):
					new_floor = "concrete"
				elif collider and collider.is_in_group("indoor_area"):
					new_floor = "indoor"
				else:
					new_floor = "terrain"
			elif collider and collider.is_in_group("concrete_area"):
				new_floor = "concrete"
			elif collider and collider.is_in_group("indoor_area"):
				new_floor = "indoor"
			else:
				new_floor = "terrain"

		# Only switch if same type detected for 10 consecutive frames
		if new_floor == pending_floor_type:
			floor_type_counter += 1
			if floor_type_counter >= 10:
				last_floor_type = new_floor
		else:
			pending_floor_type = new_floor
			floor_type_counter = 0

		if last_floor_type == "concrete":
			_play_footstep(footstep_player_concrete, desired_pitch)
			_stop_footstep(footstep_player_indoor)
			_stop_footstep(footstep_player_terrain)
		elif last_floor_type == "indoor":
			_play_footstep(footstep_player_indoor, desired_pitch)
			_stop_footstep(footstep_player_concrete)
			_stop_footstep(footstep_player_terrain)
		else:
			_play_footstep(footstep_player_terrain, desired_pitch)
			_stop_footstep(footstep_player_concrete)
			_stop_footstep(footstep_player_indoor)
	else:
		_stop_all_footsteps()
		last_floor_type = ""

func _play_footstep(player: AudioStreamPlayer3D, pitch: float):
	if player:
		player.pitch_scale = pitch
		if not player.playing:
			player.play()

func _stop_footstep(player: AudioStreamPlayer3D):
	if player and player.playing:
		player.stop()

func _stop_all_footsteps():
	_stop_footstep(footstep_player_indoor)
	_stop_footstep(footstep_player_concrete)
	_stop_footstep(footstep_player_terrain)

func headbob(headbob_time):
	var headbob_pos = Vector3.ZERO
	headbob_pos.y = sin(headbob_time * headbob_freq) * headbob_amplitude
	headbob_pos.x = cos(headbob_time * headbob_freq / 2) * headbob_amplitude
	return headbob_pos

func _on_area_3d_area_entered(_area: Area3D) -> void:
	pass

func _on_ok_button_pressed() -> void:
	pass
	
func die():
	print("player exploded unlucky")
	set_process_input(false)
	deathscreen.visible = true
	player_death.emit()
	
func _on_hitbox_body_entered(body):
	die()
