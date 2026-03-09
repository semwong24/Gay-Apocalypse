extends Node

var has_flashlight = false
var has_hatchet = false
var has_batteries = false
var has_painkillers = false
var has_lighter = false
var has_food = false
var has_water = false
var has_sleepingbag = false
var has_antiseptic = false
var has_flare = false
var has_backpack = false
var has_soda = false
var has_matchbox = false
var has_keyfob = false
var has_gas = false
var has_carbattery = false
var has_tires = false

func reset():
	has_flashlight = false
	has_hatchet = false
	has_batteries = false
	has_painkillers = false
	has_lighter = false
	has_food = false
	has_water = false
	has_sleepingbag = false
	has_antiseptic = false
	has_flare = false
	has_backpack = false
	has_soda = false
	has_matchbox = false
	has_keyfob = false
	has_gas = false
	has_carbattery = false
	has_tires = false

func pickup_item(item_name: String):
	match item_name:
		"flashlight": has_flashlight = true
		"hatchet": has_hatchet = true
		"batteries": has_batteries = true
		"painkillers": has_painkillers = true
		"lighter": has_lighter = true
		"food": has_food = true
		"water": has_water = true
		"sleepingbag": has_sleepingbag = true
		"antiseptic": has_antiseptic = true
		"flare": has_flare = true
		"backpack": has_backpack = true
		"soda": has_soda = true
		"matchbox": has_matchbox = true
		"keyfob": has_keyfob = true
		"gas": has_gas = true
		"carbattery": has_carbattery = true
		"tires": has_tires = true

func has_item(item_name: String) -> bool:
	match item_name:
		"flashlight": return has_flashlight
		"hatchet": return has_hatchet
		"batteries": return has_batteries
		"painkillers": return has_painkillers
		"lighter": return has_lighter
		"food": return has_food
		"water": return has_water
		"sleepingbag": return has_sleepingbag
		"antiseptic": return has_antiseptic
		"flare": return has_flare
		"backpack": return has_backpack
		"soda": return has_soda
		"matchbox": return has_matchbox
		"keyfob": return has_keyfob
		"gas": return has_gas
		"carbattery": return has_carbattery
		"tires": return has_tires
		_: return false
