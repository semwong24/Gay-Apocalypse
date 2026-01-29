extends Control
# or CanvasLayer if that's what this node is

func _ready():
	# Correct node path
	var start_button = $subustart/newgamebutton

	if is_instance_valid(start_button):
		start_button.pressed.connect(_on_newgamebutton_pressed)
		print("New Game button signal connected.")
	else:
		print("ERROR: newgamebutton not found. Check node path.")

func _on_newgamebutton_pressed():
	hide()
	print("Menu hidden. Game starting.")
