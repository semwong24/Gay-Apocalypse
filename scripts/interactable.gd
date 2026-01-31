extends CollisionObject3D
class_name Interactable

signal interacted(body)

@export var prompt_message = "Interact"
@export var prompt_input = "interact"
@export var item_name = ""
@export var unlocks_action = ""
@export var disappears_on_pickup = true

func get_prompt():
	var key_name = ""
	for action in InputMap.action_get_events(prompt_input):
		if action is InputEventKey:
			key_name = action.as_text_physical_keycode()
			break
			
	return prompt_message + "\n[" + key_name + "]"

func interact(body):
	if item_name != "":
		PlayerInventory.pickup_item(item_name)
	
	interacted.emit(body)

func _ready():
	interacted.connect(_on_interacted)

func _on_interacted(_body):
	if disappears_on_pickup:
		# Make it invisible and stop collision
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
	
