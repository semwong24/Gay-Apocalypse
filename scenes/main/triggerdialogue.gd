extends Area3D
@export var timeline: DialogicTimeline
@export var wait_for_opening: bool = false
@export_group("Quest Requirement")
@export var requires_quest_complete: bool = false
@export var required_quests: Array[String] = []
@export_enum("All Must Be Complete", "Any Must Be Complete") var quest_check_mode: int = 0
@export var incomplete_quest_timeline: DialogicTimeline = null

var has_triggered: bool = false
var incomplete_on_cooldown: bool = false  # NEW

func _on_load_reset():
	has_triggered = false
	incomplete_on_cooldown = false  # NEW

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
		for quest in required_quests:
			if not QuestManager.is_quest_complete(quest):
				return false
		return true
	else:
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
			if incomplete_quest_timeline != null and not incomplete_on_cooldown:
				# Check if this timeline already played or is queued
				var path = incomplete_quest_timeline.resource_path
				if path in DialogueQueue.completed_timelines:
					return
				if path in DialogueQueue.dropped_timelines:
					return
				incomplete_on_cooldown = true
				DialogueQueue.add_area_dialogue(incomplete_quest_timeline)
				# Reset cooldown after a delay so re-entry works eventually
				await get_tree().create_timer(5.0).timeout
				incomplete_on_cooldown = false
			return
	if timeline == null:
		push_error(name + ": timeline is not assigned in the inspector!")
		return
	has_triggered = true
	DialogueQueue.add_area_dialogue(timeline)
