extends Control

signal finished(success)

@export var keyString: String = "Q"
@export var keyCode: Key = KEY_Q
@export var eventDuration: = 1
@export var displayDuration: = 1

@onready var color_rect: ColorRect = %ColorRect
@onready var key_label: Label = %KeyLabel
@onready var success_label: Label = %SuccessLabel

var tween = create_tween()
var success = false

func _ready() -> void:
	add_to_group("QTE")
	key_label.text = keyString
	await _animation()
	if not success:
		hide()
	
func _animation():
	tween.tween_property(color_rect, "material:shader_parameter/value", 0, eventDuration)
	await tween.finished

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(keyCode) and not success_label.visible:
		success_label.show()
		tween.kill()
		success = true
		
		await get_tree().create_timer(displayDuration).timeout
		hide()
