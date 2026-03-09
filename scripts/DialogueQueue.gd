extends Node

signal timeline_ended_for_opening

var priority_queue: Array = []
var normal_queue: Array = []
var is_playing: bool = false
var last_played_was_opening: bool = false
var current_timeline_path: String = ""
var is_queue_managed: bool = false
var is_interactable_dialogue: bool = false
var completed_timelines: Array = []
var dropped_timelines: Array = []

const MAX_NORMAL_QUEUE_SIZE = 1

func add_area_dialogue(timeline: DialogicTimeline):
	if timeline == null:
		return
	if timeline.resource_path in completed_timelines:
		print("Skipping already-completed timeline: ", timeline.resource_path)
		return
	if timeline.resource_path in dropped_timelines:
		print("Skipping already-dropped timeline: ", timeline.resource_path)
		return
	if is_playing and current_timeline_path == timeline.resource_path:
		print("Skipping — timeline already playing: ", timeline.resource_path)
		return
	for queued in normal_queue:
		if queued.resource_path == timeline.resource_path:
			print("Skipping — timeline already queued: ", timeline.resource_path)
			return
	while normal_queue.size() >= MAX_NORMAL_QUEUE_SIZE:
		var dropped = normal_queue.pop_front()
		if dropped:
			print("Queue full, dropped: ", dropped.resource_path)
			dropped_timelines.append(dropped.resource_path)
	normal_queue.append(timeline)
	print("Area dialogue queued. Normal queue size: ", normal_queue.size())
	_try_play_next()

func add_quest_dialogue(timeline: DialogicTimeline):
	if timeline == null:
		return
	priority_queue.push_front({"timeline": timeline, "interactable": false})
	print("Quest dialogue queued. Priority queue size: ", priority_queue.size())
	_try_play_next()

func add_interactable_dialogue(timeline: DialogicTimeline):
	if timeline == null:
		return
	priority_queue.push_front({"timeline": timeline, "interactable": true})
	_try_play_next()

func skip_current():
	if not is_playing:
		return
	Dialogic.end_timeline()

func _try_play_next():
	if is_playing:
		return
	var next_timeline = null
	var next_is_interactable = false
	if not priority_queue.is_empty():
		var entry = priority_queue.pop_front()
		if entry is Dictionary:
			next_timeline = entry.timeline
			next_is_interactable = entry.get("interactable", false)
		else:
			next_timeline = entry
		print("Playing quest/interactable dialogue")
	elif not normal_queue.is_empty():
		next_timeline = normal_queue.pop_front()
	else:
		print("Queue empty, nothing to play")
		return
	is_playing = true
	is_queue_managed = true
	is_interactable_dialogue = next_is_interactable
	current_timeline_path = next_timeline.resource_path
	last_played_was_opening = ("opening" in current_timeline_path)
	print("Starting timeline: ", current_timeline_path)
	Dialogic.start(next_timeline)
	if not Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.connect(_on_timeline_ended, CONNECT_ONE_SHOT)

func _on_timeline_ended():
	if not is_playing:
		return
	print("Timeline ended: ", current_timeline_path)
	if current_timeline_path != "" and "opening" not in current_timeline_path:
		if current_timeline_path not in completed_timelines:
			completed_timelines.append(current_timeline_path)
	var layout_node = get_tree().get_meta('dialogic_layout_node', null)
	if layout_node and is_instance_valid(layout_node):
		layout_node.visible = false
	is_playing = false
	is_queue_managed = false
	is_interactable_dialogue = false
	var was_opening = last_played_was_opening
	last_played_was_opening = false
	current_timeline_path = ""
	if was_opening:
		timeline_ended_for_opening.emit()
	if priority_queue.is_empty() and normal_queue.is_empty():
		_deferred_cleanup()
	_try_play_next()

func _deferred_cleanup():
	await get_tree().process_frame
	await get_tree().process_frame
	if is_playing:
		return
	var layout_node = get_tree().get_meta('dialogic_layout_node', null)
	if layout_node and is_instance_valid(layout_node):
		layout_node.visible = false
		await get_tree().process_frame
		layout_node.queue_free()
		get_tree().remove_meta('dialogic_layout_node')

func reset():
	priority_queue.clear()
	normal_queue.clear()
	is_playing = false
	last_played_was_opening = false
	current_timeline_path = ""
	is_queue_managed = false
	is_interactable_dialogue = false
	completed_timelines = []
	dropped_timelines = []
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)
	if Dialogic.current_timeline != null:
		Dialogic.end_timeline()
