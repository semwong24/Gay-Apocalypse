extends Control
class_name QuestDisplay

var title = ""
var objectives = []
var font_size = 18
var line_height = 26
var title_color = Color(0.9, 0.9, 0.9, 1.0)
var active_color = Color(0.9, 0.9, 0.9, 1.0)
var complete_color = Color(0.55, 0.55, 0.55, 1.0)
var strikethrough_color = Color(0.769, 0.769, 0.769, 0.722)
var strikethrough_thickness = 2.5

func set_objectives(new_title: String, new_objectives: Array):
	title = new_title
	objectives = new_objectives
	queue_redraw()

func _draw():
	var font = ThemeDB.fallback_font
	var y = float(font_size)

	if title != "":
		draw_string(font, Vector2(0, y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, title_color)
		y += line_height

	for objective in objectives:
		var text = "• " + objective["text"]
		if objective["complete"]:
			draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, complete_color)
			var text_width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var mid_y = y - (font_size * 0.35)
			for i in range(int(strikethrough_thickness)):
				draw_line(
					Vector2(0, mid_y + i - strikethrough_thickness * 0.5),
					Vector2(text_width, mid_y + i - strikethrough_thickness * 0.5),
					strikethrough_color,
					1.0
				)
		else:
			draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, active_color)
		y += line_height
