extends Area3D

var quest_triggered = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	if quest_triggered:
		return
	
	if not QuestManager.is_quest_complete("Prepare for the journey ahead:"):
		PickupMessageManager.show_message("Return to the supermarket first.", 3.0)
		return
	
	quest_triggered = true
	QuestManager.next_quest_data = null
	
	if not QuestManager.is_quest_complete("Locate the gas station."):
		QuestManager.completed_quests.append("Locate the gas station.")
		QuestManager.active_quest_title = ""
		QuestManager.quest_complete = true
	
	await get_tree().create_timer(2.0).timeout
	QuestManager.start_custom_quest(
		"Find parts to start the car:",
		["Key Fob", "Gas", "Car Battery", "Tire"],
		["keyfob", "gas", "carbattery", "tires"],
		"",
		0.0
	)
