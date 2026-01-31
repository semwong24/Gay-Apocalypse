extends Node

var has_flashlight = false
# can add more items later

func pickup_item(item_name: String):
	match item_name:
		"flashlight":
			has_flashlight = true
