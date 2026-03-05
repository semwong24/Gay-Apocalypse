extends Control

@onready var credits_page = $creditspage
@onready var settings_page = $settingspage
@onready var load_page = $loadfilepage
@onready var all_pages = [credits_page, settings_page, load_page]

var click_to_continue_label: Label
var click_canvas_layer: CanvasLayer
var waiting_for_click = false

# --- Fullscreen overlay system ---
var overlay_canvas_layer: CanvasLayer
var overlay_texture_rect: TextureRect
var overlay_mode: String = ""  # "volume_warning" or "credits"

func _ready():
	for page in all_pages:
		page.hide()

	GameState.ui_open = true

	var start_button = $subustart/newgamebutton
	if is_instance_valid(start_button):
		start_button.pressed.connect(_on_newgamebutton_pressed)
		print("New Game button signal connected.")
	else:
		print("ERROR: newgamebutton not found. Check node path.")

	await get_tree().process_frame
	_setup_click_text()
	_setup_overlay()

func _setup_overlay():
	overlay_canvas_layer = CanvasLayer.new()
	overlay_canvas_layer.layer = 200
	overlay_canvas_layer.name = "OverlayLayer"
	get_tree().root.add_child(overlay_canvas_layer)

	overlay_texture_rect = TextureRect.new()
	overlay_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	overlay_texture_rect.anchor_left = 0.0
	overlay_texture_rect.anchor_top = 0.0
	overlay_texture_rect.anchor_right = 1.0
	overlay_texture_rect.anchor_bottom = 1.0
	overlay_texture_rect.offset_left = 0.0
	overlay_texture_rect.offset_top = 0.0
	overlay_texture_rect.offset_right = 0.0
	overlay_texture_rect.offset_bottom = 0.0
	overlay_texture_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_texture_rect.visible = false
	overlay_texture_rect.name = "OverlayImage"

	overlay_canvas_layer.add_child(overlay_texture_rect)

func _show_overlay(image_path: String, mode: String):
	var texture = load(image_path)
	if texture == null:
		print("ERROR: Could not load image at path: ", image_path)
		return
	overlay_texture_rect.texture = texture
	overlay_texture_rect.visible = true
	overlay_mode = mode
	# Force fill viewport size on next frame
	await get_tree().process_frame
	var vp_size = get_viewport().get_visible_rect().size
	overlay_texture_rect.position = Vector2.ZERO
	overlay_texture_rect.size = vp_size

func _hide_overlay():
	overlay_texture_rect.visible = false
	overlay_mode = ""

func _setup_click_text():
	var viewport_size = get_viewport().get_visible_rect().size

	click_canvas_layer = CanvasLayer.new()
	click_canvas_layer.layer = 100
	click_canvas_layer.name = "ClickToContinueLayer"
	get_tree().root.add_child(click_canvas_layer)

	click_to_continue_label = Label.new()
	click_to_continue_label.text = "[Click to cycle through comic]"
	click_to_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	click_to_continue_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	click_to_continue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	click_to_continue_label.visible = false
	click_to_continue_label.name = "ClickToContinueLabel"

	click_to_continue_label.position = Vector2.ZERO
	click_to_continue_label.size = viewport_size

	click_to_continue_label.add_theme_font_size_override("font_size", 25)
	click_to_continue_label.add_theme_color_override("font_color", Color.WHITE)
	click_to_continue_label.add_theme_constant_override("line_spacing", -50)

	click_canvas_layer.add_child(click_to_continue_label)

# ---- Button handlers ----

func _on_newgamebutton_pressed():
	GameState.ui_open = false
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_show_overlay("res://assets/UI Assets/audiowarning.png", "volume_warning")

func _on_creditsbutton_pressed() -> void:
	_show_overlay("res://assets/UI Assets/credits.png", "credits")

func _on_settingsbutton_pressed() -> void:
	_show_page(settings_page)

func _on_loadfilebutton_pressed() -> void:
	_show_page(load_page)

func _show_page(target_page):
	for page in all_pages:
		page.visible = (page == target_page)

func _start_game():
	print("Click detected. Comic will continue playing.")

# ---- Input handling ----

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:

		# Handle overlay clicks first (highest priority)
		if overlay_texture_rect != null and overlay_texture_rect.visible:
			match overlay_mode:
				"volume_warning":
					_hide_overlay()
					Dialogic.start("opening")
					if click_to_continue_label:
						click_to_continue_label.visible = true
						waiting_for_click = true
				"credits":
					_hide_overlay()
					show()
					GameState.ui_open = true
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_viewport().set_input_as_handled()
			return

		# Handle click-to-continue for comic
		if waiting_for_click:
			waiting_for_click = false
			click_to_continue_label.visible = false
			_start_game()
			return

		# Dismiss sub-pages if clicking outside them
		for page in all_pages:
			if page.visible:
				var rect = page.get_global_rect()
				if not rect.has_point(event.global_position):
					page.hide()
