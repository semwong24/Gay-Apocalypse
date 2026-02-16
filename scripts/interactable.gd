extends CollisionObject3D
class_name Interactable
signal interacted(body)
@export var prompt_message = "Interact"
@export var prompt_input = "interact"
@export var item_name = ""
@export var unlocks_action = ""
@export var disappears_on_pickup = true

# Pickup message settings
@export_group("Pickup Message")
@export var show_pickup_message = true
@export var pickup_message = ""
@export var message_duration = 3.0

# Requirement settings
@export_group("Requirements")
@export var requires_items = false  
@export var required_item_names: Array[String] = [] 
@export var requires_dialogue_finished = false
@export var required_dialogue_name = ""
@export var locked_message = "Locked"

# teleport settings
@export_group("Teleportation")
@export var teleports_player = false
@export var teleport_position: Vector3 = Vector3.ZERO
@export var teleport_marker: Marker3D

func _ready():
	interacted.connect(_on_interacted)

func get_prompt():
	if requires_dialogue_finished:
		var dialogue_finished = Dialogic.VAR.get(required_dialogue_name) if Dialogic.VAR.has(required_dialogue_name) else false
		if not dialogue_finished:
			return locked_message
	
	if requires_items and not has_all_required_items():
		return locked_message
		
	var key_name = ""
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
	if requires_dialogue_finished:
		var dialogue_finished = Dialogic.VAR.get(required_dialogue_name) if Dialogic.VAR.has(required_dialogue_name) else false
		if not dialogue_finished:
			print("Need to finish dialogue: ", required_dialogue_name)
			return
	
	if requires_items and not has_all_required_items():
		print("Need items: ", required_item_names)
		return 
		
	if item_name != "":
		PlayerInventory.pickup_item(item_name)
		if show_pickup_message:
			var display_message = pickup_message
			if "{item}" in display_message:
				display_message = display_message.replace("{item}", item_name)
			PickupMessageManager.show_message(display_message, message_duration)
	
	if teleports_player:
		teleport_player(body)
	
	interacted.emit(body)

func teleport_player(body):
	if body.is_in_group("player") or body.has_method("teleport"):
		var destination = teleport_marker.global_position if teleport_marker else teleport_position
		body.global_position = destination

func _on_interacted(_body):
	if disappears_on_pickup:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
