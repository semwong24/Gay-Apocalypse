extends Node

var quest_ui: CanvasLayer
var quest_container: QuestDisplay
var current_quest_objectives = []
var on_complete_message = ""
var on_complete_duration = 3.0
var current_quest_title = ""
var complete_message_canvas: CanvasLayer
var quest_complete = false

func _ready():
	Dialogic.timeline_ended.connect(_on_timeline_ended)

func _on_timeline_ended():
	start_custom_quest(
		"Objectives:",
		["Find flashlight", "Grab hatchet"],
		["flashlight", "hatchet"],
		"Front door unlocked.",
		3.0
	)

func start_custom_quest(title: String, objectives: Array, keys: Array, complete_message: String, complete_duration: float):
	current_quest_title = title
	current_quest_objectives = []
	on_complete_message = complete_message
	on_complete_duration = complete_duration
	quest_complete = false
	for i in range(objectives.size()):
		var key = keys[i] if i < keys.size() else ""
		current_quest_objectives.append({"text": objectives[i], "complete": false, "key": key})
	if not quest_ui:
		await _build_ui()
	_update_ui()

func notify_item_collected(item_name: String):
	for objective in current_quest_objectives:
		if objective["key"] == item_name and not objective["complete"]:
			objective["complete"] = true
			_update_ui()
			_check_all_complete()
			break

func hide_complete_message():
	quest_complete = false
	if complete_message_canvas:
		complete_message_canvas.queue_free()
		complete_message_canvas = null

func _check_all_complete():
	for objective in current_quest_objectives:
		if not objective["complete"]:
			return
	quest_complete = true
	if on_complete_message != "":
		await get_tree().create_timer(2.5).timeout
		if not quest_complete:
			return
		
		var viewport_size = get_viewport().get_visible_rect().size
		var viewport = get_tree().root
		complete_message_canvas = CanvasLayer.new()
		complete_message_canvas.layer = 100
		viewport.add_child(complete_message_canvas)
		
		var label = Label.new()
		label.text = on_complete_message
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 2)
		label.position = Vector2(0, viewport_size.y - 150)
		label.size = Vector2(viewport_size.x, 100)
		complete_message_canvas.add_child(label)
		
		var timer = Timer.new()
		timer.one_shot = true
		timer.timeout.connect(func(): hide_complete_message())
		complete_message_canvas.add_child(timer)
		timer.start(on_complete_duration)

func _build_ui():
	if quest_ui:
		quest_ui.queue_free()

	await get_tree().process_frame

	quest_ui = CanvasLayer.new()
	quest_ui.layer = 99
	get_tree().root.add_child(quest_ui)

	quest_container = QuestDisplay.new()
	quest_container.position = Vector2(20, 20)
	quest_container.size = Vector2(300, 400)
	quest_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_ui.add_child(quest_container)

func _update_ui():
	if not quest_container:
		return
	quest_container.set_objectives(current_quest_title, current_quest_objectives)
