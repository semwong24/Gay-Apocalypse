extends Control

@onready var credits_page = $creditspage
@onready var settings_page = $settingspage
@onready var load_page = $loadfilepage

@onready var all_pages = [credits_page, settings_page, load_page]

func _ready():
	for page in all_pages:
		page.hide()

func _on_newgamebutton_pressed():
	hide()

func _on_creditsbutton_pressed() -> void:
	_show_page(credits_page)

func _on_settingsbutton_pressed() -> void:
	_show_page(settings_page)

func _on_loadfilebutton_pressed() -> void:
	_show_page(load_page)

func _show_page(target_page):
	for page in all_pages:
		page.visible = (page == target_page)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		for page in all_pages:
			if page.visible:
				# Check if the click was OUTSIDE the current page's area
				var rect = page.get_global_rect()
				if not rect.has_point(event.global_position):
					page.hide()
