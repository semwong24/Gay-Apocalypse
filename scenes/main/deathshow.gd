extends CanvasLayer

@onready var load_button = $LoadButton
@onready var quit_button = $QuitButton

var button_overlays: Dictionary = {}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 500
	visible = false
	await get_tree().process_frame
	if not load_button:
		print("ERROR: LoadButton not found")
		return
	if not quit_button:
		print("ERROR: QuitButton not found")
		return
	_setup_button(load_button)
	_setup_button(quit_button)
	load_button.pressed.connect(_on_load)
	quit_button.pressed.connect(_on_quit_to_main)

func show_death_screen():
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	GameState.ui_open = true
	var texture_rect = TextureRect.new()
	texture_rect.texture = load("res://assets/UI Assets/gameover.png")
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.anchor_left = 0.0
	texture_rect.anchor_top = 0.0
	texture_rect.anchor_right = 1.0
	texture_rect.anchor_bottom = 1.0
	texture_rect.offset_left = 0.0
	texture_rect.offset_top = 0.0
	texture_rect.offset_right = 0.0
	texture_rect.offset_bottom = 0.0
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(texture_rect)
	move_child(texture_rect, 0)

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

func _on_load():
	var player = get_tree().get_first_node_in_group("player")
	if not SaveManager.has_save():
		print("No save file found.")
		return
	get_tree().paused = false
	GameState.ui_open = false
	GameState.is_new_game = false
	visible = false

	DialogueQueue.priority_queue.clear()
	DialogueQueue.normal_queue.clear()
	DialogueQueue.is_playing = false
	DialogueQueue.current_timeline_path = ""
	DialogueQueue.is_queue_managed = false
	DialogueQueue.is_interactable_dialogue = false
	DialogueQueue.completed_timelines = []
	DialogueQueue.dropped_timelines = []
	if Dialogic.timeline_ended.is_connected(DialogueQueue._on_timeline_ended):
		Dialogic.timeline_ended.disconnect(DialogueQueue._on_timeline_ended)

	for node in get_tree().root.get_children():
		if node is CanvasLayer and node.name in [
			"ClickToContinueLayer", "OverlayLayer",
			"DialogicLayout_DialogueStyle"
		]:
			node.queue_free()
	if get_tree().has_meta("dialogic_layout_node"):
		var layout_node = get_tree().get_meta("dialogic_layout_node")
		if is_instance_valid(layout_node):
			layout_node.queue_free()
		get_tree().remove_meta("dialogic_layout_node")
	QuestManager.reset()
	PlayerInventory.reset()
	# Clean up any lingering dialogue layout nodes
	for node in get_tree().root.get_children():
		if node is CanvasLayer and node.name in [
			"ClickToContinueLayer", "OverlayLayer",
			"DialogicLayout_DialogueStyle"
		]:
			node.queue_free()
	if get_tree().has_meta("dialogic_layout_node"):
		var layout_node = get_tree().get_meta("dialogic_layout_node")
		if is_instance_valid(layout_node):
			layout_node.queue_free()
		get_tree().remove_meta("dialogic_layout_node")
		
		
	# Reconnect signal that reset() disconnected
	if not DialogueQueue.timeline_ended_for_opening.is_connected(QuestManager._on_opening_finished):
		DialogueQueue.timeline_ended_for_opening.connect(QuestManager._on_opening_finished)
	if player:
		player.set_process_input(true)
		player.set_physics_process(true)
		await SaveManager.load_game(player)
		print("completed_timelines after load: ", DialogueQueue.completed_timelines)
		print("dropped_timelines after load: ", DialogueQueue.dropped_timelines)
		print("current_timeline_path in save: ", DialogueQueue.current_timeline_path)
		player.velocity = Vector3.ZERO
		var anim = player.get_node_or_null("Head/arms walkie talkie rig/AnimationPlayer")
		if anim:
			anim.play("speak down")
		await get_tree().process_frame
		await get_tree().process_frame
		for node in get_tree().get_nodes_in_group("interactable"):
			if node.item_name != "" and node.disappears_on_pickup and PlayerInventory.has_item(node.item_name):
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
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		print("ERROR: Player not found for loading.")

func _on_quit_to_main():
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
