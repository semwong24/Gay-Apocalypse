extends Camera3D


@onready var raycast = $RayCast3D

func _process(_delta):
	var looking_at = raycast.get_collider()
	
	if looking_at and looking_at.has_method("interact"):
		show_prompt("Press E to interact")
		
		if Input.is_action_just_pressed("interact"):
			looking_at.interact()
	else:
		hide_prompt()

func show_prompt(text):
	# Update UI label or sprite
	pass

func hide_prompt():
	# Hide the UI prompt
	pass
