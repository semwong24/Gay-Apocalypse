extends CharacterBody3D

@export var speed := 4.0
@export var sprint_speed := 7.0
@export var mouse_sensitivity := 0.2
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var cam: Camera3D
@export var flashlight: SpotLight3D
@export_group("headbob")
@export var headbob_freq := 2.0
@export var headbob_amplitude := 0.04

# Stamina system
@export_group("Stamina")
@export var max_stamina := 100.0
@export var stamina_drain_rate := 20.0
@export var stamina_regen_rate := 15.0
@export var stamina_required_to_sprint := 65.0
@export var sprint_cooldown_after_depletion := 1.0
var current_stamina := 100.0
var is_on_sprint_cooldown := false
var cooldown_timer := 0.0


signal sprint_started
signal sprint_stopped


enum FloorType { NONE, INDOOR, CONCRETE }
var current_floor_type = FloorType.NONE

@onready var footstep_player_indoor = $FootstepPlayerIndoors
@onready var footstep_player_concrete = $FootstepPlayerConcrete 
var footstep_timer = 0.0
@export var footstep_interval = 0.5

var headbob_time := 0.0
var flashlight_on = false
var is_sprinting = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	flashlight.visible = false
	current_stamina = max_stamina
	
	call_deferred("_connect_to_floor_areas")
	
func _connect_to_floor_areas():
	# Connect to indoor area
	var indoor_area = get_tree().get_first_node_in_group("indoor_area")
	if indoor_area:
		indoor_area.body_entered.connect(_on_indoor_area_entered)
		indoor_area.body_exited.connect(_on_indoor_area_exited)
		if indoor_area.overlaps_body(self):
			current_floor_type = FloorType.INDOOR
	
	# Connect to concrete area
	var concrete_area = get_tree().get_first_node_in_group("concrete_area")
	if concrete_area:
		concrete_area.body_entered.connect(_on_concrete_area_entered)
		concrete_area.body_exited.connect(_on_concrete_area_exited)
		if concrete_area.overlaps_body(self):
			current_floor_type = FloorType.CONCRETE
	
func _input(event):
	if GameState.comic_playing or GameState.ui_open:
		return
	
	if event.is_action_pressed("skip_dialogue") and Dialogic.current_timeline != null:
		Dialogic.VAR.set("opening_finished", true)
		Dialogic.end_timeline()
			
	if event.is_action_pressed("toggle_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Only process mouse look when cursor is captured
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
			print("Sprint cooldown ended!")
	

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
				print("Stamina depleted! Cooldown started.")
	else:
		if can_sprint:
			is_sprinting = true
	
	if is_sprinting and not was_sprinting:
		print("Player is sprinting")
		sprint_started.emit()
	elif not is_sprinting and was_sprinting:
		print("Player stopped sprinting")
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
	headbob_time += delta * velocity.length() * float(is_on_floor())
	cam.transform.origin = headbob(headbob_time)
	
	handle_footsteps(delta)

func handle_stamina(delta):
	var is_moving = velocity.length() > 0.1
	
	if is_sprinting and is_moving:
		current_stamina -= stamina_drain_rate * delta
		current_stamina = max(0, current_stamina)
		
		if current_stamina < stamina_required_to_sprint:
			print("Not enough stamina! Need to rest.")
	else:
		current_stamina += stamina_regen_rate * delta
		current_stamina = min(max_stamina, current_stamina)

func handle_footsteps(_delta):
	if GameState.comic_playing:
		_stop_all_footsteps()
		return
	
	var is_moving = velocity.length() > 0.1
	
	if is_moving and current_floor_type != FloorType.NONE:
		var desired_pitch = 1.3 if is_sprinting else 1.0
		
		# Play the appropriate footstep sound based on floor type
		match current_floor_type:
			FloorType.INDOOR:
				_play_footstep(footstep_player_indoor, desired_pitch)
				_stop_footstep(footstep_player_concrete)
			FloorType.CONCRETE:
				_play_footstep(footstep_player_concrete, desired_pitch)
				_stop_footstep(footstep_player_indoor)
	else:
		_stop_all_footsteps()

func _play_footstep(player: AudioStreamPlayer, pitch: float):
	if player:
		player.pitch_scale = pitch
		if not player.playing:
			player.play()

func _stop_footstep(player: AudioStreamPlayer):
	if player and player.playing:
		player.stop()

func _stop_all_footsteps():
	_stop_footstep(footstep_player_indoor)
	_stop_footstep(footstep_player_concrete)

# Indoor area callbacks
func _on_indoor_area_entered(body: Node3D) -> void:
	if body == self:
		current_floor_type = FloorType.INDOOR

func _on_indoor_area_exited(body):
	if body == self:
		current_floor_type = FloorType.NONE
		_stop_all_footsteps()

# Concrete area callbacks
func _on_concrete_area_entered(body: Node3D) -> void:
	if body == self:
		current_floor_type = FloorType.CONCRETE

func _on_concrete_area_exited(body):
	if body == self:
		current_floor_type = FloorType.NONE
		_stop_all_footsteps()

func headbob(headbob_time):
	var headbob_pos = Vector3.ZERO
	headbob_pos.y = sin(headbob_time * headbob_freq)*headbob_amplitude
	headbob_pos.x = cos(headbob_time * headbob_freq/2) * headbob_amplitude
	return headbob_pos

func _on_area_3d_area_entered(_area: Area3D) -> void:
	pass

func _on_ok_button_pressed() -> void:
	pass
