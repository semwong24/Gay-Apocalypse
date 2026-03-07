extends Node
var current_choice_index = 0
var choice_buttons = []
var last_button_count = 0

func _ready():
	return

func _process(_delta):
	var layout = Dialogic.Styles.get_layout_node()
	if layout:
		var buttons = _find_all_buttons(layout)
		if buttons.size() > 0:
			choice_buttons = buttons
			if buttons.size() != last_button_count:
				current_choice_index = 0
				last_button_count = buttons.size()
				_highlight_choice(current_choice_index)
				_connect_hover_signals()
			current_choice_index = clamp(current_choice_index, 0, choice_buttons.size() - 1)
			if Input.is_action_just_pressed("dialogue_scroll_down") or Input.is_action_just_pressed("ui_down"):
				current_choice_index = (current_choice_index + 1) % choice_buttons.size()
				_highlight_choice(current_choice_index)
			if Input.is_action_just_pressed("dialogue_scroll_up") or Input.is_action_just_pressed("ui_up"):
				current_choice_index = (current_choice_index - 1 + choice_buttons.size()) % choice_buttons.size()
				_highlight_choice(current_choice_index)
			if Input.is_action_just_pressed("dialogue_select") or Input.is_action_just_pressed("ui_accept"):
				var opposite_index = (choice_buttons.size() - 1) - current_choice_index
				choice_buttons[opposite_index].emit_signal("choice_selected")
		else:
			last_button_count = 0
			current_choice_index = 0

func _connect_hover_signals() -> void:
	for i in range(choice_buttons.size()):
		var btn = choice_buttons[i]
		if not btn.mouse_entered.is_connected(_on_button_hovered.bind(i)):
			btn.mouse_entered.connect(_on_button_hovered.bind(i))

func _on_button_hovered(index: int) -> void:
	current_choice_index = index
	_highlight_choice(current_choice_index)

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
			choice_buttons[i].modulate = Color.WHITE
		else:
			choice_buttons[i].modulate = Color(1.3, 1.3, 0.8)
