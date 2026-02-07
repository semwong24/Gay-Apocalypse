extends Node

var has_flashlight = false
var has_hatchet = false
# can add more items later

func pickup_item(item_name: String):
	match item_name:
		"flashlight":
			has_flashlight = true
		"hatchet":
			has_hatchet = true

func has_item(item_name: String) -> bool:
	match item_name:
		"flashlight":
			return has_flashlight
		"hatchet":
			return has_hatchet
		_:
			return false
