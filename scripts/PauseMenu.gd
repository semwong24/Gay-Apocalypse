extends CanvasLayer

@onready var main_menu = $"../mainUI"
var is_paused: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	# Force TextureRect to fill screen
	await get_tree().process_frame
	var vp = get_viewport().get_visible_rect().size
	$TextureRect.position = Vector2.ZERO
	$TextureRect.size = vp
	$TextureRect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	$TextureRect.stretch_mode = TextureRect.STRETCH_SCALE
	
	$TextureRect/ResumeButton.pressed.connect(_on_resume)
	$TextureRect/SaveLoadButton.pressed.connect(_on_save_load)
	$TextureRect/QuitButton.pressed.connect(_on_quit_to_main)

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
	is_paused = true
	get_tree().paused = true
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	GameState.ui_open = true

func _on_resume():
	is_paused = false
	get_tree().paused = false
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GameState.ui_open = false

func _on_save_load():
	print("Save/Load — not yet implemented.")

func _on_quit_to_main():
	is_paused = false
	get_tree().paused = false
	get_tree().reload_current_scene()
