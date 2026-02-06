extends AnimationPlayer

@export var character_name = "Jessie"  
@export var speak_down_cooldown = 12.0 
var is_sprinting = false

var last_speak_time = 0.0
var currently_holding_radio = false

func _ready():
	Dialogic.timeline_started.connect(_on_dialog_started)
	Dialogic.timeline_ended.connect(_on_dialog_ended)
	Dialogic.Text.about_to_show_text.connect(_on_text_about_to_show)

func _process(_delta):
	handle_sprint_input()

func handle_sprint_input():
	var wants_to_sprint = Input.is_action_pressed("sprint")
	
	if wants_to_sprint:
		if not is_sprinting:
			start_sprint()
	else:
		if is_sprinting:
			stop_sprint()

func start_sprint():
	is_sprinting = true
	if not currently_holding_radio:
		play("run")

func stop_sprint():
	is_sprinting = false
	if not currently_holding_radio:
		play("speak down", -1, 100)
			
			
func _on_text_about_to_show(info: Dictionary):
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if info.has("character") and info.character != null:
		var speaker = info.character
		var speaker_name = speaker.display_name
		
		if speaker_name == character_name:
			# Jessie is speaking 
			if not currently_holding_radio:
				play("speak")
				currently_holding_radio = true
				last_speak_time = current_time
		else:
			# Only play "speak down" if cooldown has passed and Jessie is holding radio
			if currently_holding_radio and (current_time - last_speak_time >= speak_down_cooldown):
				play("speak down")
				currently_holding_radio = false
	else:
		# Narrator speaking
		if currently_holding_radio and (current_time - last_speak_time >= speak_down_cooldown):
			play("speak down")
			currently_holding_radio = false

func _on_dialog_started():
	last_speak_time = 0.0
	currently_holding_radio = false

func _on_dialog_ended():
	if currently_holding_radio:
		play("speak down")  
	currently_holding_radio = false
