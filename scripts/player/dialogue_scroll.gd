extends Node

var current_choice_index = 0
var choice_buttons = []

func _ready():
	return

func _process(_delta):
	var layout = Dialogic.Styles.get_layout_node()
	if layout:
		var buttons = _find_all_buttons(layout)
		if buttons.size() > 0:
			choice_buttons = buttons
			
			if Input.is_action_just_pressed("dialogue_scroll_down"):
				current_choice_index = (current_choice_index + 1) % choice_buttons.size()
				_highlight_choice(current_choice_index)
			
			if Input.is_action_just_pressed("dialogue_scroll_up"):
				current_choice_index = (current_choice_index - 1 + choice_buttons.size()) % choice_buttons.size()
				_highlight_choice(current_choice_index)
			
			if Input.is_action_just_pressed("dialogue_select") or Input.is_action_just_pressed("ui_accept"):
				choice_buttons[current_choice_index].emit_signal("choice_selected")

func _find_all_buttons(node):
	var buttons = []
	if node is Button and node.visible:
		buttons.append(node)
	for child in node.get_children():
		buttons.append_array(_find_all_buttons(child))
	return buttons

func _highlight_choice(index: int):
	for i in range(choice_buttons.size()):
		if i == index:
			choice_buttons[i].grab_focus()
			choice_buttons[i].modulate = Color(1.3, 1.3, 0.8)
		else:
			choice_buttons[i].modulate = Color.WHITE
