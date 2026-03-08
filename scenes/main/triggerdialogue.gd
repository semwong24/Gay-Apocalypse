extends Area3D

@export var timeline: DialogicTimeline

var has_triggered: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	if not body.is_in_group("player"):
		return
	if has_triggered:
		return
		
	has_triggered = true
	print("Timeline started") # confirm this only prints once
	Dialogic.start(timeline)

	has_triggered = true
	_start_timeline()

func _start_timeline():
	var dialogic_node = Dialogic.start(timeline)
	# If something stops the timeline externally, this won't re-trigger
	# because has_triggered is already true
	dialogic_node.connect("timeline_ended", _on_timeline_ended)

func _on_timeline_ended():
	pass  # Timeline finished naturally — do nothing, or reset has_triggered here
		  # if you want it to be re-triggerable
