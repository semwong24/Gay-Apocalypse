extends CollisionObject3D
class_name Interactable
signal interacted(body)
@export var prompt_message = "Interact"
@export var prompt_input = "interact"
@export var item_name = ""
@export var unlocks_action = ""
@export var disappears_on_pickup = true

@export_group("Pickup Message")
@export var show_pickup_message = true
@export var pickup_message = ""
@export var message_duration = 3.0

@export_group("Requirements")
@export var requires_items = false
@export var required_item_names: Array[String] = []
@export var requires_dialogue_finished = false
@export var required_dialogue_name = ""
@export var requires_quest_complete = false
@export var required_quest_title = ""
@export var locked_message = "Locked"

@export_group("Teleportation")
@export var teleports_player = false
@export var teleport_position: Vector3 = Vector3.ZERO
@export var teleport_marker: Marker3D

@export_group("Quest")
@export var starts_quest = false
@export var auto_start_on_quest_complete = false
@export var quest_title = ""
@export var quest_objectives: Array[String] = []
@export var quest_objective_keys: Array[String] = []
@export var quest_complete_message = ""
@export var quest_complete_message_duration = 3.0
@export var completes_quest_key = ""
@export var quest_optional_title = ""
@export var quest_optional_objectives: Array[String] = []
@export var quest_optional_keys: Array[String] = []
@export var plays_dialogue_on_quest_start = false

@export_group("Dialogue")
@export var plays_dialogue = false
@export var dialogue_timeline: DialogicTimeline = null
@export var dialogue_duration = 0.0

@export_group("Scene Change")
@export var changes_scene = false
@export var target_scene: String = ""

var is_interacting = false

func _ready():
	interacted.connect(_on_interacted)

func get_prompt():
	if requires_dialogue_finished:
		var dialogue_finished = Dialogic.VAR.get(required_dialogue_name) if Dialogic.VAR.has(required_dialogue_name) else false
		if not dialogue_finished:
			return locked_message

	if requires_quest_complete and required_quest_title != "":
		if not QuestManager.is_quest_complete(required_quest_title):
			return locked_message

	if requires_items and not has_all_required_items():
		return locked_message

	var key_name = ""
	if prompt_input != null and prompt_input != "" and InputMap.has_action(prompt_input):
		for action in InputMap.action_get_events(prompt_input):
			if action is InputEventKey:
				key_name = action.as_text_physical_keycode()
				break

	return prompt_message + "\n[" + key_name + "]"

func has_all_required_items() -> bool:
	if required_item_names.is_empty():
		return true
	for item in required_item_names:
		if not PlayerInventory.has_item(item):
			return false
	return true

func interact(body):
	if is_interacting:
		return
	is_interacting = true

	if requires_dialogue_finished:
		var dialogue_finished = Dialogic.VAR.get(required_dialogue_name) if Dialogic.VAR.has(required_dialogue_name) else false
		if not dialogue_finished:
			print("Need to finish dialogue: ", required_dialogue_name)
			is_interacting = false
			return

	if requires_quest_complete and required_quest_title != "":
		if not QuestManager.is_quest_complete(required_quest_title):
			print("Quest not complete yet: ", required_quest_title)
			is_interacting = false
			return

	if requires_items and not has_all_required_items():
		print("Need items: ", required_item_names)
		for item in required_item_names:
			print("has ", item, ": ", PlayerInventory.has_item(item))
		is_interacting = false
		return

	if disappears_on_pickup:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED

	if item_name != null and item_name != "":
		PlayerInventory.pickup_item(item_name)
		QuestManager.notify_item_collected(item_name)
		if show_pickup_message:
			var display_message = pickup_message
			if "{item}" in display_message:
				display_message = display_message.replace("{item}", item_name)
			PickupMessageManager.show_message(display_message, message_duration)

	if completes_quest_key != null and completes_quest_key != "":
		QuestManager.notify_item_collected(completes_quest_key)

	if teleports_player:
		teleport_player(body)
		await get_tree().process_frame

	if changes_scene and target_scene != "":
		QuestManager.hide_quest_ui()
		SceneTransition.fade_to_scene(target_scene)
		is_interacting = false
		return

	if starts_quest:
		if auto_start_on_quest_complete:
			QuestManager.queue_next_quest(
				quest_title if quest_title != null else "",
				quest_objectives,
				quest_objective_keys,
				quest_complete_message if quest_complete_message != null else "",
				quest_complete_message_duration,
				quest_optional_title if quest_optional_title != null else "",
				quest_optional_objectives,
				quest_optional_keys
			)
		elif not requires_quest_complete or QuestManager.is_quest_complete(required_quest_title):
			QuestManager.start_custom_quest(
				quest_title if quest_title != null else "",
				quest_objectives,
				quest_objective_keys,
				quest_complete_message if quest_complete_message != null else "",
				quest_complete_message_duration,
				quest_optional_title if quest_optional_title != null else "",
				quest_optional_objectives,
				quest_optional_keys
			)

	if plays_dialogue and dialogue_timeline != null:
		await get_tree().process_frame
		await get_tree().process_frame
		if plays_dialogue_on_quest_start:
			if not QuestManager.is_quest_active(quest_title):
				await QuestManager.quest_started
		DialogueQueue.add_interactable_dialogue(dialogue_timeline)

	interacted.emit(body)
	await get_tree().process_frame
	is_interacting = false

func teleport_player(body):
	if body.is_in_group("player") or body.has_method("teleport"):
		var destination = teleport_marker.global_position if teleport_marker else teleport_position
		body.global_position = destination

func _on_interacted(_body):
	if item_name == "doorknob":
		QuestManager.hide_complete_message()
	if disappears_on_pickup:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
