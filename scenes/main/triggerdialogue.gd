extends Area3D
@export var timeline: DialogicTimeline
@export var wait_for_opening: bool = false
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

func _on_body_entered(body: Node3D):
	if not body.is_in_group("player"):
		return
	if has_triggered:
		print(name + ": already triggered, skipping")
		return
	if timeline == null:
		push_error(name + ": timeline is not assigned in the inspector!")
		return
	has_triggered = true
	DialogueQueue.add_area_dialogue(timeline)
