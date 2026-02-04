extends Control

@onready var timer: Timer = $Timer

const QTE = preload("res://qte.tscn")

var keyList = [
	{"keyString": "Q", "keyCode": KEY_Q},
	{"keyString": "E", "keyCode": KEY_E},
]

var count = 0
var keyPressedList = []
func _on_timer_timeout() -> void:
	if count == keyList.size():
		timer.stop()
		return
	
	var keyNode = QTE.instantiate()
	keyNode.finished.connect(_on_key_finished)
	keyNode.keyCode = keyList[count].keyCode
	keyNode.eyString = keyList[count].keyString
	
	add_child(keyNode)
	count += 1
	
func _on_key_finished(keySuccess):
	keyPressedList.append(keySuccess)
