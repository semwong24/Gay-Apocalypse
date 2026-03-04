extends Node3D

@export var car: Node3D
@export var cinematic_camera: Camera3D
@export var credits_scene: String = ""

var elapsed = 0.0
var car_speed = 0.0
var car_acceleration = 4.0
var car_max_speed = 20.0
var camera_rise_speed = 1.5
var fading = false
var fade_alpha = 0.0
var car_start_position: Vector3
var fade_distance = 50.0

func _ready():
	cinematic_camera.current = true
	car_start_position = car.global_position

func _process(delta):
	elapsed += delta
	
	if not fading:
		car_speed = min(car_speed + car_acceleration * delta, car_max_speed)
		car.global_position.z -= car_speed * delta
		cinematic_camera.global_position.y += camera_rise_speed * delta
		
		var distance_traveled = abs(car.global_position.z - car_start_position.z)
		if distance_traveled >= fade_distance:
			fading = true
	else:
		fade_alpha = min(fade_alpha + delta * 0.8, 1.0)
		
		if fade_alpha >= 1.0:
			if credits_scene != "":
				SceneTransition.fade_to_scene(credits_scene, false)
			else:
				get_tree().quit()
