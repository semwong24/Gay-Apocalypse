extends Node

const SAVE_PATH = "user://savegame.json"

func save_game(player: CharacterBody3D):
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
		"opening_finished": Dialogic.VAR.get("opening_finished") if Dialogic.VAR.has("opening_finished") else false
	}

	data["quest"] = {
		"completed_quests": QuestManager.completed_quests,
		"active_quest_title": QuestManager.active_quest_title,
		"current_quest_title": QuestManager.current_quest_title,
		"quest_complete": QuestManager.quest_complete,
		"objectives": QuestManager.current_quest_objectives,
		"optional_objectives": QuestManager.current_quest_optional_objectives,
		"optional_title": QuestManager.current_optional_title
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

	# Player position and rotation
	var pos = data["player_position"]
	player.global_position = Vector3(pos["x"], pos["y"], pos["z"])
	player.rotation.y = data["player_rotation"]["y"]

	# Inventory
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

	# Dialogic variables
	var dvars = data["dialogic_vars"]
	Dialogic.VAR.set("opening_finished", dvars["opening_finished"])

	# Quest state
	var quest = data["quest"]
	QuestManager.completed_quests = quest["completed_quests"]
	QuestManager.active_quest_title = quest["active_quest_title"]
	QuestManager.current_quest_title = quest["current_quest_title"]
	QuestManager.quest_complete = quest["quest_complete"]
	QuestManager.current_quest_objectives = quest["objectives"]
	QuestManager.current_quest_optional_objectives = quest["optional_objectives"]
	QuestManager.current_optional_title = quest["optional_title"]

	# Rebuild quest UI if there's an active quest
	if QuestManager.active_quest_title != "":
		await QuestManager._build_ui()
		await get_tree().process_frame
		await get_tree().process_frame
		QuestManager._update_ui()

	# Audio
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
	var vp = get_tree().root.get_viewport().get_visible_rect().size
	label.position = Vector2(vp.x - label.size.x - 20, 20)

	await get_tree().create_timer(2.0).timeout
	var tween = canvas.create_tween()
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 1.0)
	await tween.finished
	canvas.queue_free()
