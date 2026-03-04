extends Node

var message_label: Label
var message_timer: Timer
var canvas_layer: CanvasLayer

func _ready():
	_setup_message_display()

func _setup_message_display():
	await get_tree().process_frame
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.name = "PickupMessageLayer"
	
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	message_label.add_theme_font_size_override("font_size", 24)
	
	message_label.add_theme_color_override("font_color", Color(0.704, 0.704, 0.704, 1.0))
	
	message_label.add_theme_color_override("font_outline_color", Color.BLACK)
	message_label.add_theme_constant_override("outline_size", 2)
	message_label.visible = false
	
	message_label.position = Vector2(0, viewport_size.y - 150)
	message_label.size = Vector2(viewport_size.x, 100)
	
	canvas_layer.add_child(message_label)
	add_child(canvas_layer)
	
	message_timer = Timer.new()
	message_timer.one_shot = true
	message_timer.timeout.connect(_hide_message)
	canvas_layer.add_child(message_timer)

func show_message(text: String, duration: float):
	if message_label:
		message_label.text = text
		message_label.visible = true
		message_timer.start(duration)
		print("Showing message: ", text, " for ", duration, " seconds")

func _hide_message():
	if message_label:
		message_label.visible = false
		print("Message hidden")
