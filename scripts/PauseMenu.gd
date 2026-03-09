extends CanvasLayer

@onready var main_menu = $"../mainUI"
@onready var resume_button = $ResumeButton
@onready var save_load_button = $SaveLoadButton
@onready var quit_button = $QuitButton

var is_paused: bool = false
var button_overlays: Dictionary = {}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 300
	hide()
	await get_tree().process_frame
	var vp = get_viewport().get_visible_rect().size
	$TextureRect.position = Vector2.ZERO
	$TextureRect.size = vp
	$TextureRect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	$TextureRect.stretch_mode = TextureRect.STRETCH_SCALE
	$TextureRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_button(resume_button)
	_setup_button(save_load_button)
	_setup_button(quit_button)
	resume_button.pressed.connect(_on_resume)
	save_load_button.pressed.connect(_on_save_load)
	quit_button.pressed.connect(_on_quit_to_main)

func _setup_button(btn: Button):
	var style_empty = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", style_empty)
	btn.add_theme_stylebox_override("hover", style_empty)
	btn.add_theme_stylebox_override("pressed", style_empty)
	btn.add_theme_stylebox_override("focus", style_empty)
	btn.text = ""
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var overlay = ColorRect.new()
	overlay.position = btn.position
	overlay.size = btn.size
	overlay.color = Color(0, 0, 0, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	move_child(overlay, get_child_count() - 2)
	button_overlays[btn] = overlay
	btn.mouse_entered.connect(func():
		overlay.color = Color(0, 0, 0, 0.55)
		_draw_border(overlay, true)
	)
	btn.mouse_exited.connect(func():
		overlay.color = Color(0, 0, 0, 0.0)
		_draw_border(overlay, false)
	)
	btn.button_down.connect(func():
		overlay.color = Color(0, 0, 0, 0.75)
	)
	btn.button_up.connect(func():
		overlay.color = Color(0, 0, 0, 0.55)
	)

func _draw_border(overlay: ColorRect, visible: bool):
	for child in overlay.get_children():
		child.queue_free()
	if not visible:
		return
	var thickness = 2
	var w = overlay.size.x
	var h = overlay.size.y
	var color = Color(1, 1, 1, 1.0)
	for border in [
		[Vector2(0, 0), Vector2(w, thickness)],
		[Vector2(0, h - thickness), Vector2(w, thickness)],
		[Vector2(0, 0), Vector2(thickness, h)],
		[Vector2(w - thickness, 0), Vector2(thickness, h)]
	]:
		var rect = ColorRect.new()
		rect.position = border[0]
		rect.size = border[1]
		rect.color = color
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(rect)

func _cleanup_orphaned_layers():
	for node in get_tree().root.get_children():
		if node is CanvasLayer and node.name in ["ClickToContinueLayer", "OverlayLayer"]:
			node.queue_free()

func _input(event):
	if event.is_action_pressed("menu"):
		if is_instance_valid(main_menu) and main_menu.visible:
			return
		if GameState.comic_playing:
			return
		if is_paused:
			_on_resume()
		else:
			_open_pause()

func _open_pause():
	_cleanup_orphaned_layers()
	is_paused = true
	get_tree().paused = true
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	GameState.ui_open = true

func _on_resume():
	is_paused = false
	get_tree().paused = false
	hide()
	PickupMessageManager._hide_message()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GameState.ui_open = false

func _on_save_load():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		SaveManager.save_game(player)
	else:
		print("ERROR: Player not found.")

func _on_quit_to_main():
	is_paused = false
	get_tree().paused = false
	GameState.reset_player_rotation = true
	DialogueQueue.reset()
	QuestManager.reset()
	PlayerInventory.reset()
	GameState.reset()
	Dialogic.VAR.set("opening_finished", false)
	for node in get_tree().root.get_children():
		if node is CanvasLayer and node.name in [
			"ClickToContinueLayer", "OverlayLayer",
			"DialogicLayout_DialogueStyle"
		]:
			node.queue_free()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().reload_current_scene()
