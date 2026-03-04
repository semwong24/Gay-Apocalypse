extends CanvasLayer

var overlay: ColorRect

func _ready():
	layer = 200
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().process_frame
	overlay.size = get_viewport().get_visible_rect().size
	add_child(overlay)

func fade_to_scene(path: String, fade_in: bool = true):
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0.0, 0.0, 0.0, 1), 2.0)
	await tween.finished
	get_tree().change_scene_to_file(path)
	
	if fade_in:
		await get_tree().process_frame
		var tween2 = create_tween()
		tween2.tween_property(overlay, "color", Color(0, 0, 0, 0), 2.0)
