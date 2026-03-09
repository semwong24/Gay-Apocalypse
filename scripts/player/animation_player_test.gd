extends AnimationPlayer
@export var character_name = "Jessie"  
@export var speak_down_cooldown = 8.0 
@export var player: CharacterBody3D  
var last_speak_time = 0.0
var currently_holding_radio = false
@onready var walkie_beep = $LowPitchBeep
@onready var radio_click = $RadioClick

func _ready():
	Dialogic.timeline_started.connect(_on_dialog_started)
	Dialogic.Text.about_to_show_text.connect(_on_text_about_to_show)
	Dialogic.Text.animation_textbox_hide.connect(_on_textbox_hide)

	if player:
		player.sprint_started.connect(_on_sprint_started)
		player.sprint_stopped.connect(_on_sprint_stopped)

func _on_sprint_started():
	if not currently_holding_radio:
		play("run")

func _on_sprint_stopped():
	if not currently_holding_radio:
		var anim_length = get_animation("speak down").length
		play("speak down")
		seek(anim_length * 0.7)

func _on_textbox_hide():
	if DialogueQueue.is_interactable_dialogue:
		return
	if currently_holding_radio:
		play("speak down")
		radio_click.play()
		currently_holding_radio = false

func _on_text_about_to_show(info: Dictionary):
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if info.has("character") and info.character != null:
		var speaker = info.character
		var speaker_name = speaker.display_name
		
		if speaker_name == character_name:
			if not currently_holding_radio:
				if DialogueQueue.is_interactable_dialogue:
					return
				play("speak")
				walkie_beep.play()
				currently_holding_radio = true
				last_speak_time = current_time
		else:
			if currently_holding_radio and (current_time - last_speak_time >= speak_down_cooldown):
				play("speak down")
				radio_click.play()
				currently_holding_radio = false
	else:
		if currently_holding_radio and (current_time - last_speak_time >= speak_down_cooldown):
			play("speak down")
			radio_click.play()
			currently_holding_radio = false

func _on_dialog_started():
	if DialogueQueue.is_interactable_dialogue:
		return
	last_speak_time = 0.0
	currently_holding_radio = false


func reset():
	stop()
	last_speak_time = 0.0
	currently_holding_radio = false
	if player:
		player.rotation.y = 0.0
		var head = player.get_node_or_null("Head")
		if head:
			head.rotation.x = 0.0
			head.rotation.z = 0.0
