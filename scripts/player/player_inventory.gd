extends Node

var has_flashlight = false
var has_hatchet = false
var has_batteries = false
var has_painkillers = false
var has_lighter = false
# can add more items later

func pickup_item(item_name: String):
	match item_name:
		"flashlight":
			has_flashlight = true
		"hatchet":
			has_hatchet = true
		"batteries":
			has_flashlight = true
		"painkillers":
			has_hatchet = true
		"lighter":
			has_hatchet = true

func has_item(item_name: String) -> bool:
	match item_name:
		"flashlight":
			return has_flashlight
		"hatchet":
			return has_hatchet
		"batteries":
			return has_flashlight
		"painkillers":
			return has_hatchet
		"lighter":
			return has_hatchet
		_:
			return false
