extends CollisionObject3D
class_name Interactable

signal interacted(body)

@export var prompt_message = "Interact"
@export var prompt_input = "interact"
@export var item_name = ""
@export var unlocks_action = ""
@export var disappears_on_pickup = true

# Requirement settings
@export_group("Requirements")
@export var requires_item = false
@export var required_item_name = ""
@export var locked_message = "Locked"

# teleport settings
@export_group("Teleportation")
@export var teleports_player = false
@export var teleport_position: Vector3 = Vector3.ZERO
@export var teleport_marker: Marker3D

func get_prompt():
	if requires_item and not PlayerInventory.has_item(required_item_name):
		return locked_message
		
	var key_name = ""
	for action in InputMap.action_get_events(prompt_input):
		if action is InputEventKey:
			key_name = action.as_text_physical_keycode()
			break
			
	return prompt_message + "\n[" + key_name + "]"

func interact(body):
	if requires_item and not PlayerInventory.has_item(required_item_name):
		print("Need item: ", required_item_name)
		return 
		
	if item_name != "":
		PlayerInventory.pickup_item(item_name)
	
	if teleports_player:
		teleport_player(body)
	
	interacted.emit(body)


func teleport_player(body):
	if body.is_in_group("player") or body.has_method("teleport"):
		var destination = teleport_marker.global_position if teleport_marker else teleport_position
		body.global_position = destination


func _ready():
	interacted.connect(_on_interacted)

func _on_interacted(_body):
	if disappears_on_pickup:
		# Make it invisible and stop collision
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
	
