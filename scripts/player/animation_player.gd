extends AnimationPlayer


func _ready():
	# Connect to Dialogic signals
	Dialogic.timeline_started.connect(_on_dialog_started)
	Dialogic.timeline_ended.connect(_on_dialog_ended)

func _on_dialog_started():
	play("speak")

func _on_dialog_ended():
	play("speak down")
