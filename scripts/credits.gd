extends Control

@export var credits_text: String = "Thank you for playing."
var elapsed = 0.0
var fade_in_duration = 2.0
var display_duration = 5.0
var fade_out_duration = 2.0
var label: Label
var alpha = 0.0

func _ready():
	await get_tree().process_frame
	SceneTransition.overlay.color = Color(0, 0, 0, 0)
	label = Label.new()
	label.text = credits_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	add_child(label)

func _process(delta):
	elapsed += delta
	
	if elapsed < fade_in_duration:
		alpha = elapsed / fade_in_duration
	elif elapsed < fade_in_duration + display_duration:
		alpha = 1.0
	elif elapsed < fade_in_duration + display_duration + fade_out_duration:
		alpha = 1.0 - (elapsed - fade_in_duration - display_duration) / fade_out_duration
	else:
		get_tree().quit()
	
	if label:
		label.add_theme_color_override("font_color", Color(1, 1, 1, alpha))
