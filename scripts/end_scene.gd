extends Node3D

@onready var ambient_wind: AudioStreamPlayer = $AmbientWind
@onready var ambient_crickets: AudioStreamPlayer = $AmbientCrickets

@export var enddemo_zoom := 1.5

@export var car: Node3D
@export var cinematic_camera: Camera3D
var elapsed = 0.0
var car_speed = 0.0
var car_acceleration = 4.0
var car_max_speed = 20.0
var camera_rise_speed = 1.5
var fading = false
var fade_alpha = 0.0
var car_start_position: Vector3
var fade_distance = 50.0

var overlay_canvas: CanvasLayer
var overlay_rect: TextureRect
var fade_rect: ColorRect
var showing_end_screen = false
var end_screen_timer = 0.0
var end_screen_duration = 3.0
var showing_credits = false

func _ready():
	cinematic_camera.current = true
	car_start_position = car.global_position
	_setup_overlay()
	ambient_wind.play()
	ambient_crickets.play()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _setup_overlay():
	overlay_canvas = CanvasLayer.new()
	overlay_canvas.layer = 100
	add_child(overlay_canvas)

	overlay_rect = TextureRect.new()
	overlay_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay_rect.stretch_mode = TextureRect.STRETCH_SCALE
	overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_rect.visible = false
	overlay_canvas.add_child(overlay_rect)

	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_canvas.add_child(fade_rect)

	await get_tree().process_frame
	var vp = get_viewport().get_visible_rect().size
	overlay_rect.position = Vector2.ZERO
	overlay_rect.size = vp
	fade_rect.position = Vector2.ZERO
	fade_rect.size = vp

func _process(delta):
	elapsed += delta

	if showing_end_screen:
		end_screen_timer += delta
		if end_screen_timer >= end_screen_duration:
			showing_end_screen = false
			showing_credits = true
			_show_image("res://assets/UI Assets/credits.png")
		return
		
	if showing_credits:
		return

	if not fading:
		car_speed = min(car_speed + car_acceleration * delta, car_max_speed)
		car.global_position.z -= car_speed * delta
		cinematic_camera.global_position.y += camera_rise_speed * delta

		var distance_traveled = abs(car.global_position.z - car_start_position.z)
		if distance_traveled >= fade_distance:
			fading = true
	else:
		fade_alpha = min(fade_alpha + delta * 0.8, 1.0)
		fade_rect.color = Color(0, 0, 0, fade_alpha)

		if fade_alpha >= 1.0:
			_show_image("res://assets/UI Assets/enddemo.png")
			var tween = create_tween()
			tween.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 1.0)
			fading = false
			showing_end_screen = true
			end_screen_timer = 0.0

func _show_image(path: String):
	var texture = load(path)	
	if texture == null:
		print("ERROR: Could not load image: ", path)
		return
	overlay_rect.texture = texture
	overlay_rect.visible = true
	
	var vp = get_viewport().get_visible_rect().size
	if path.ends_with("enddemo.png"):
		var zoomed_size = vp * enddemo_zoom
		overlay_rect.size = zoomed_size
		overlay_rect.position = (vp - zoomed_size) / 2  # keeps it centered
	else:
		overlay_rect.size = vp
		overlay_rect.position = Vector2.ZERO
		
	fade_rect.color = Color(0, 0, 0, 1)
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 1.0)

func _input(event):
	if event.is_action_pressed("toggle_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
