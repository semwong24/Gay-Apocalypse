extends Control

@onready var credits_page = $creditspage
@onready var settings_page = $settingspage
@onready var load_page = $loadfilepage
@onready var all_pages = [credits_page, settings_page, load_page]
var confirm_canvas: CanvasLayer

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

func _on_loadfilebutton_pressed():
	if SaveManager.has_save():
		_show_load_confirmation()
	else:
		PickupMessageManager.show_message("No save file found.", 3.0)

func _show_load_confirmation():
	var vp = get_viewport().get_visible_rect().size

	confirm_canvas = CanvasLayer.new()
	confirm_canvas.layer = 150
	get_tree().root.add_child(confirm_canvas)

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.position = Vector2.ZERO
	bg.size = vp
	confirm_canvas.add_child(bg)

	var box = PanelContainer.new()
	box.size = Vector2(400, 180)
	box.position = (vp / 2) - (box.size / 2)
	confirm_canvas.add_child(box)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	box.add_child(vbox)

	var label = Label.new()
	label.text = "Load saved game?\nUnsaved progress will be lost."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(label)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)

	var load_btn = Button.new()
	load_btn.text = "Load Game"
	load_btn.custom_minimum_size = Vector2(120, 40)
	load_btn.pressed.connect(_on_confirm_load)
	hbox.add_child(load_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(120, 40)
	cancel_btn.pressed.connect(_on_cancel_load)
	hbox.add_child(cancel_btn)

func _on_confirm_load():
	_close_load_confirmation()
	hide()
	GameState.ui_open = false
	GameState.comic_playing = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		await SaveManager.load_game(player)
		player.velocity = Vector3.ZERO
		var anim = player.get_node_or_null("Head/arms walkie talkie rig/AnimationPlayer")
		if anim:
			anim.play("speak down")
			
			
		await get_tree().process_frame
		await get_tree().process_frame
	
		for node in get_tree().get_nodes_in_group("interactable"):
			if node.item_name != "" and PlayerInventory.has_item(node.item_name):
				node.visible = false
				node.process_mode = Node.PROCESS_MODE_DISABLED
				
		if PlayerInventory.has_flashlight:
			var flashlight_node = get_tree().root.find_child("Flashlight", true, false)
			if flashlight_node:
				flashlight_node.visible = false
				flashlight_node.process_mode = Node.PROCESS_MODE_DISABLED
		if PlayerInventory.has_hatchet:
			var hatchet_node = get_tree().root.find_child("Hatchet", true, false)
			if hatchet_node:
				hatchet_node.visible = false
				hatchet_node.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		print("ERROR: Player not found for loading.")

func _on_cancel_load():
	_close_load_confirmation()

func _close_load_confirmation():
	if confirm_canvas:
		confirm_canvas.queue_free()
		confirm_canvas = null


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
