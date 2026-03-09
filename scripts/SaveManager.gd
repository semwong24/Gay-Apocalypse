extends Node

const SAVE_PATH = "user://savegame.json"

func save_game(player: CharacterBody3D):
	if GameState.is_new_game:
		print("Save blocked — new game not finished yet")
		return
	if QuestManager.completed_quests.is_empty() and QuestManager.active_quest_title == "":
		print("Save blocked — no quest state yet")
		return

	var data = {}
	data["player_position"] = {
		"x": player.global_position.x,
		"y": player.global_position.y,
		"z": player.global_position.z
	}
	data["player_rotation"] = {
		"y": player.rotation.y
	}
	data["inventory"] = {
		"has_flashlight": PlayerInventory.has_flashlight,
		"has_hatchet": PlayerInventory.has_hatchet,
		"has_batteries": PlayerInventory.has_batteries,
		"has_painkillers": PlayerInventory.has_painkillers,
		"has_lighter": PlayerInventory.has_lighter,
		"has_food": PlayerInventory.has_food,
		"has_water": PlayerInventory.has_water,
		"has_sleepingbag": PlayerInventory.has_sleepingbag,
		"has_antiseptic": PlayerInventory.has_antiseptic,
		"has_flare": PlayerInventory.has_flare,
		"has_backpack": PlayerInventory.has_backpack,
		"has_soda": PlayerInventory.has_soda,
		"has_matchbox": PlayerInventory.has_matchbox,
		"has_keyfob": PlayerInventory.has_keyfob,
		"has_gas": PlayerInventory.has_gas,
		"has_carbattery": PlayerInventory.has_carbattery,
		"has_tires": PlayerInventory.has_tires
	}
	data["dialogic_vars"] = {
		"opening_finished": true
	}
	var timeline_to_save = ""
	var current_path = DialogueQueue.current_timeline_path
	if current_path != "" and "opening" not in current_path:
		timeline_to_save = current_path
	data["dialogue"] = {
		"current_timeline_path": timeline_to_save,
		"completed_timelines": DialogueQueue.completed_timelines,
		"dropped_timelines": DialogueQueue.dropped_timelines
	}
	data["quest"] = {
		"completed_quests": QuestManager.completed_quests,
		"active_quest_title": QuestManager.active_quest_title,
		"current_quest_title": QuestManager.current_quest_title,
		"quest_complete": QuestManager.quest_complete,
		"objectives": QuestManager.current_quest_objectives,
		"optional_objectives": QuestManager.current_quest_optional_objectives,
		"optional_title": QuestManager.current_optional_title,
		"on_complete_message": QuestManager.on_complete_message,
		"on_complete_duration": QuestManager.on_complete_duration
	}
	data["flags"] = {
		"supermarket_quest_finished": QuestManager.is_quest_complete("Prepare for the journey ahead:"),
		"gas_station_entered": QuestManager.is_quest_complete("Locate the gas station.")
	}
	data["audio"] = {
		"master_volume": AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	}
	data["timestamp"] = Time.get_datetime_string_from_system()

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		print("Game saved.")
	else:
		print("ERROR: Could not write save file.")
	_show_save_indicator()

func load_game(player: CharacterBody3D):
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found.")
		return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		print("ERROR: Could not read save file.")
		return false
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null:
		print("ERROR: Save file corrupted.")
		return false

	Dialogic.VAR.set("opening_finished", true)

	var pos = data["player_position"]
	player.global_position = Vector3(pos["x"], pos["y"], pos["z"])
	player.rotation.y = data["player_rotation"]["y"]

	var inv = data["inventory"]
	PlayerInventory.has_flashlight = inv["has_flashlight"]
	PlayerInventory.has_hatchet = inv["has_hatchet"]
	PlayerInventory.has_batteries = inv["has_batteries"]
	PlayerInventory.has_painkillers = inv["has_painkillers"]
	PlayerInventory.has_lighter = inv["has_lighter"]
	PlayerInventory.has_food = inv["has_food"]
	PlayerInventory.has_water = inv["has_water"]
	PlayerInventory.has_sleepingbag = inv["has_sleepingbag"]
	PlayerInventory.has_antiseptic = inv["has_antiseptic"]
	PlayerInventory.has_flare = inv["has_flare"]
	PlayerInventory.has_backpack = inv["has_backpack"]
	PlayerInventory.has_soda = inv["has_soda"]
	PlayerInventory.has_matchbox = inv["has_matchbox"]
	PlayerInventory.has_keyfob = inv["has_keyfob"]
	PlayerInventory.has_gas = inv["has_gas"]
	PlayerInventory.has_carbattery = inv["has_carbattery"]
	PlayerInventory.has_tires = inv["has_tires"]

	var quest = data["quest"]
	QuestManager.completed_quests = quest["completed_quests"]
	QuestManager.active_quest_title = quest["active_quest_title"]
	QuestManager.current_quest_title = quest["current_quest_title"]
	QuestManager.quest_complete = quest["quest_complete"]
	QuestManager.current_quest_objectives = quest["objectives"]
	QuestManager.current_quest_optional_objectives = quest["optional_objectives"]
	QuestManager.current_optional_title = quest["optional_title"]
	QuestManager.on_complete_message = quest.get("on_complete_message", "")
	QuestManager.on_complete_duration = quest.get("on_complete_duration", 3.0)
	print("Quest state loaded - active: ", QuestManager.active_quest_title)
	print("Quest current_quest_title: ", QuestManager.current_quest_title)
	print("Quest completed_quests: ", QuestManager.completed_quests)

	if QuestManager.current_quest_title != "":
		print("Rebuilding quest UI for: ", QuestManager.current_quest_title)
		await QuestManager._build_ui()

	if data.has("dialogue"):
		if data["dialogue"].has("completed_timelines"):
			DialogueQueue.completed_timelines = data["dialogue"]["completed_timelines"]
		if data["dialogue"].has("dropped_timelines"):
			DialogueQueue.dropped_timelines = data["dialogue"]["dropped_timelines"]
		var timeline_path = data["dialogue"]["current_timeline_path"]
		if timeline_path != "" and "opening" not in timeline_path:
			await get_tree().process_frame
			var timeline = load(timeline_path)
			if timeline:
				DialogueQueue.add_area_dialogue(timeline)
				print("Resumed timeline: ", timeline_path)

	var audio = data["audio"]
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), audio["master_volume"])

	print("Game loaded.")
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("Save deleted.")

func _show_save_indicator():
	var canvas = CanvasLayer.new()
	canvas.layer = 200
	get_tree().root.add_child(canvas)
	var label = Label.new()
	label.text = "✓ Game Saved"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	canvas.add_child(label)
	await get_tree().process_frame
	await get_tree().process_frame
	var vp = get_tree().root.get_viewport().get_visible_rect().size
	label.position = Vector2(vp.x - label.size.x - 20, 20)
	await get_tree().create_timer(2.0).timeout
	var tween = canvas.create_tween()
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 1.0)
	await tween.finished
	canvas.queue_free()
