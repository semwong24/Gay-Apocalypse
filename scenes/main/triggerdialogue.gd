extends Area3D
@export var timeline: DialogicTimeline
@export var wait_for_opening: bool = false

@export_group("Quest Requirement")
@export var requires_quest_complete: bool = false
@export var required_quests: Array[String] = []
@export_enum("All Must Be Complete", "Any Must Be Complete") var quest_check_mode: int = 0
@export var incomplete_quest_timeline: DialogicTimeline = null

var has_triggered: bool = false

func _on_load_reset():
	has_triggered = false

func _ready():
	add_to_group("dialogue_area")
	body_entered.connect(_on_body_entered)
	if wait_for_opening:
		await DialogueQueue.timeline_ended_for_opening
	await get_tree().process_frame
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_on_body_entered(body)
			break

func _quests_satisfied() -> bool:
	if quest_check_mode == 0:
		# All must be complete
		for quest in required_quests:
			if not QuestManager.is_quest_complete(quest):
				return false
		return true
	else:
		# Any must be complete
		for quest in required_quests:
			if QuestManager.is_quest_complete(quest):
				return true
		return false

func _on_body_entered(body: Node3D):
	if not body.is_in_group("player"):
		return
	if has_triggered:
		print(name + ": already triggered, skipping")
		return
	if requires_quest_complete:
		if not _quests_satisfied():
			if incomplete_quest_timeline != null:
				# Don't set has_triggered so it can recheck when player re-enters
				DialogueQueue.add_area_dialogue(incomplete_quest_timeline)
			return
	if timeline == null:
		push_error(name + ": timeline is not assigned in the inspector!")
		return
	has_triggered = true
	DialogueQueue.add_area_dialogue(timeline)
