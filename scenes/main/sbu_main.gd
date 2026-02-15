extends Control
@onready var credits_page = $creditspage
@onready var settings_page = $settingspage
@onready var load_page = $loadfilepage
@onready var all_pages = [credits_page, settings_page, load_page]

var click_to_continue_label: Label
var click_canvas_layer: CanvasLayer
var waiting_for_click = false

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

func _setup_click_text():
	var viewport_size = get_viewport().get_visible_rect().size
	
	click_canvas_layer = CanvasLayer.new()
	click_canvas_layer.layer = 100  
	click_canvas_layer.name = "ClickToContinueLayer"
	get_tree().root.add_child(click_canvas_layer)
	
	# Create label
	click_to_continue_label = Label.new()
	click_to_continue_label.text = "[Click to continue]"
	click_to_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	click_to_continue_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM 
	click_to_continue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	click_to_continue_label.visible = false
	click_to_continue_label.name = "ClickToContinueLabel"
	

	click_to_continue_label.position = Vector2.ZERO
	click_to_continue_label.size = viewport_size
	
	
	click_to_continue_label.add_theme_font_size_override("font_size", 32)
	click_to_continue_label.add_theme_color_override("font_color", Color.WHITE)
	click_to_continue_label.add_theme_constant_override("line_spacing", -50)  
	
	click_canvas_layer.add_child(click_to_continue_label)

func _on_newgamebutton_pressed():
	GameState.ui_open = false
	hide()
	
	Dialogic.start("opening")
	
	if click_to_continue_label:
		click_to_continue_label.visible = true
		waiting_for_click = true

func _start_game():
	print("Click detected. Comic will continue playing.")

func _on_creditsbutton_pressed() -> void:
	_show_page(credits_page)

func _on_settingsbutton_pressed() -> void:
	_show_page(settings_page)

func _on_loadfilebutton_pressed() -> void:
	_show_page(load_page)

func _show_page(target_page):
	for page in all_pages:
		page.visible = (page == target_page)

func _input(event):
	if waiting_for_click and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		waiting_for_click = false
		click_to_continue_label.visible = false
		_start_game()
		return  
	
	if event is InputEventMouseButton and event.pressed:
		for page in all_pages:
			if page.visible:
				var rect = page.get_global_rect()
				if not rect.has_point(event.global_position):
					page.hide()
