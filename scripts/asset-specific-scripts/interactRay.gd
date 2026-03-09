@tool
extends RayCast3D
@onready var prompt = $Prompt
@export var normal_prompt_offset := Vector2(0, 0):
	set(value):
		normal_prompt_offset = value
		if prompt and not was_dialogue_active:
			prompt.position = value
@export var dialogue_prompt_offset := Vector2(0, -200):
	set(value):
		dialogue_prompt_offset = value
		if prompt and was_dialogue_active:
			prompt.position = value
var was_dialogue_active = false
func _ready():
	if prompt:
		prompt.position = normal_prompt_offset
	if owner:
		add_exception(owner)
func _physics_process(_delta):
	if Engine.is_editor_hint():
		return
	force_raycast_update()
	var is_dialogue_active = Dialogic.current_timeline != null
	if is_dialogue_active != was_dialogue_active:
		if is_dialogue_active:
			prompt.position = dialogue_prompt_offset
		else:
			prompt.position = normal_prompt_offset
	was_dialogue_active = is_dialogue_active
	prompt.text = ""
	if is_colliding():
		var collider = get_collider()
		if is_dialogue_active:
			prompt.text = ""
			return
		if collider.has_method("interact"):
			prompt.text = collider.get_prompt()
			if collider.prompt_input != null and collider.prompt_input != "" and InputMap.has_action(collider.prompt_input):
				if Input.is_action_just_pressed(collider.prompt_input):
					collider.interact(owner)
		else:
			prompt.text = ""
	else:
		prompt.text = ""
