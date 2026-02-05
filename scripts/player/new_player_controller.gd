extends CharacterBody3D

@export var speed := 5.0
@export var mouse_sensitivity := 0.2
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var cam: Camera3D
@export var flashlight: SpotLight3D
@export_group("headbob")
@export var headbob_freq := 2.0
@export var headbob_amplitude := 0.04
#@export var sprite: Sprite3D
var headbob_time := 0.0

var flashlight_on = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#sprite.position.y = cam.position.y
	flashlight.visible = false
	
func _input(event):
		
	if event.is_action_pressed("toggle_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity * 0.01)
		$Head.rotate_x(-event.relative.y * mouse_sensitivity * 0.01)
		$Head.rotation_degrees.x = clamp($Head.rotation_degrees.x, -89, 89)
		flashlight.rotation = cam.rotation
		
func _physics_process(delta):
	if Input.is_action_just_pressed("toggle_flashlight") and PlayerInventory.has_flashlight:
		flashlight_on = !flashlight_on
		flashlight.visible = flashlight_on

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
		
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()
	headbob_time += delta * velocity.length() * float(is_on_floor())
	cam.transform.origin = headbob(headbob_time)

func headbob(headbob_time):
	var headbob_pos = Vector3.ZERO
	headbob_pos.y = sin(headbob_time * headbob_freq)*headbob_amplitude
	headbob_pos.x = cos(headbob_time * headbob_freq/2) * headbob_amplitude
	return headbob_pos
func _on_area_3d_area_entered(_area: Area3D) -> void:
	pass # Replace with function body.

func _on_ok_button_pressed() -> void:
	pass # Replace with function body.
