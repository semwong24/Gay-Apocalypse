extends Node

signal quest_started(title)
signal quest_completed

var quest_ui: CanvasLayer = null
var quest_container: QuestDisplay = null
var current_quest_objectives = []
var current_quest_optional_objectives = []
var on_complete_message = ""
var on_complete_duration = 3.0
var current_quest_title = ""
var current_optional_title = ""
var complete_message_canvas: CanvasLayer = null
var quest_complete = false
var active_quest_title = ""
var completed_quests: Array = []
var next_quest_data = null
var current_complete_timeline: DialogicTimeline = null

func _ready():
	quest_ui = null
	quest_container = null
	complete_message_canvas = null
	DialogueQueue.timeline_ended_for_opening.connect(_on_opening_finished)

func _on_opening_finished():
	print("is_new_game: ", GameState.is_new_game)
	if not GameState.is_new_game:
		print("Skipping — not a new game")
		return
	GameState.is_new_game = false
	start_custom_quest(
		"Objectives:",
		["Find flashlight", "Grab hatchet"],
		["flashlight", "hatchet"],
		"Front door unlocked.",
		3.0
	)

func is_quest_active(title: String) -> bool:
	return active_quest_title == title

func is_quest_complete(title: String) -> bool:
	return title in completed_quests

func hide_quest_ui():
	if quest_ui and is_instance_valid(quest_ui):
		quest_ui.visible = false

func queue_next_quest(title: String, objectives: Array, keys: Array, complete_message: String, complete_duration: float, optional_title: String = "", optional_objectives: Array = [], optional_keys: Array = [], complete_timeline: DialogicTimeline = null):
	next_quest_data = {
		"title": title,
		"objectives": objectives,
		"keys": keys,
		"complete_message": complete_message,
		"complete_duration": complete_duration,
		"optional_title": optional_title,
		"optional_objectives": optional_objectives,
		"optional_keys": optional_keys,
		"complete_timeline": complete_timeline
	}

func start_custom_quest(title: String, objectives: Array, keys: Array, complete_message: String, complete_duration: float, optional_title: String = "", optional_objectives: Array = [], optional_keys: Array = [], complete_timeline: DialogicTimeline = null):
	current_quest_title = title
	active_quest_title = title
	current_quest_objectives = []
	current_quest_optional_objectives = []
	current_optional_title = optional_title
	on_complete_message = complete_message
	on_complete_duration = complete_duration
	quest_complete = false
	current_complete_timeline = complete_timeline
	for i in range(objectives.size()):
		var key = keys[i] if i < keys.size() else ""
		current_quest_objectives.append({"text": objectives[i], "complete": false, "key": key})
	for i in range(optional_objectives.size()):
		var key = optional_keys[i] if i < optional_keys.size() else ""
		current_quest_optional_objectives.append({"text": optional_objectives[i], "complete": false, "key": key})
	if not quest_ui or not is_instance_valid(quest_ui):
		await _build_ui()
	else:
		quest_ui.visible = true
		quest_container.set_objectives(current_quest_title, current_quest_objectives, current_optional_title, current_quest_optional_objectives)
	quest_started.emit(title)

func notify_item_collected(item_name: String):
	var found = false
	for objective in current_quest_objectives:
		if objective["key"] == item_name and not objective["complete"]:
			objective["complete"] = true
			found = true
			break
	if not found:
		for objective in current_quest_optional_objectives:
			if objective["key"] == item_name and not objective["complete"]:
				objective["complete"] = true
				break
	_update_ui()
	_check_all_complete()

func hide_complete_message():
	if complete_message_canvas and is_instance_valid(complete_message_canvas):
		complete_message_canvas.queue_free()
		complete_message_canvas = null

func _check_all_complete():
	for objective in current_quest_objectives:
		if not objective["complete"]:
			return
	if quest_complete:
		return
	quest_complete = true
	active_quest_title = ""
	completed_quests.append(current_quest_title)
	quest_completed.emit()

	if current_complete_timeline != null:
		var path = current_complete_timeline.resource_path
		if path not in DialogueQueue.completed_timelines:
			DialogueQueue.add_quest_dialogue(current_complete_timeline)
		else:
			print("Skipping complete timeline — already played: ", path)
		current_complete_timeline = null

	if current_quest_title != "Find parts to start the car:":
		var player = get_tree().get_first_node_in_group("player")
		if player:
			SaveManager.save_game(player)

	if next_quest_data != null:
		var data = next_quest_data
		next_quest_data = null
		start_custom_quest(
			data["title"],
			data["objectives"],
			data["keys"],
			data["complete_message"],
			data["complete_duration"],
			data["optional_title"],
			data["optional_objectives"],
			data["optional_keys"],
			data.get("complete_timeline", null)
		)

	if on_complete_message != "":
		await get_tree().create_timer(3).timeout
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
	if quest_ui and is_instance_valid(quest_ui):
		quest_ui.queue_free()
	quest_ui = null
	quest_container = null
	await get_tree().process_frame
	quest_ui = CanvasLayer.new()
	quest_ui.layer = 50
	get_tree().root.add_child(quest_ui)
	quest_container = QuestDisplay.new()
	quest_container.position = Vector2(20, 20)
	quest_container.size = Vector2(300, 400)
	quest_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_ui.add_child(quest_container)
	quest_container.set_objectives(current_quest_title, current_quest_objectives, current_optional_title, current_quest_optional_objectives)

func _update_ui():
	if not quest_container or not is_instance_valid(quest_container):
		return
	quest_container.set_objectives(current_quest_title, current_quest_objectives, current_optional_title, current_quest_optional_objectives)

func reset():
	if DialogueQueue.timeline_ended_for_opening.is_connected(_on_opening_finished):
		DialogueQueue.timeline_ended_for_opening.disconnect(_on_opening_finished)
	current_quest_objectives = []
	current_quest_optional_objectives = []
	on_complete_message = ""
	on_complete_duration = 3.0
	current_quest_title = ""
	current_optional_title = ""
	quest_complete = false
	active_quest_title = ""
	completed_quests = []
	next_quest_data = null
	current_complete_timeline = null
	if quest_ui and is_instance_valid(quest_ui):
		quest_ui.queue_free()
	quest_ui = null
	quest_container = null
	if complete_message_canvas and is_instance_valid(complete_message_canvas):
		complete_message_canvas.queue_free()
	complete_message_canvas = null
