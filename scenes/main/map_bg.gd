extends TextureRect

@export var move_strength := 40.0
@export var smoothness := 6.0
@export var min_horizontal_padding := 60.0

var viewport_size: Vector2
var max_offset: Vector2
var target_position: Vector2

func _ready():
	viewport_size = get_viewport_rect().size

	# Get original texture size
	var tex_size = texture.get_size()
	var tex_ratio = tex_size.x / tex_size.y
	var view_ratio = viewport_size.x / viewport_size.y

	# Calculate actual scaled texture size (Keep Aspect Covered)
	var scaled_size: Vector2
	if tex_ratio > view_ratio:
		scaled_size = Vector2(
			viewport_size.y * tex_ratio,
			viewport_size.y
		)
	else:
		scaled_size = Vector2(
			viewport_size.x,
			viewport_size.x / tex_ratio
		)

	# Extra space available for movement
	max_offset = (scaled_size - viewport_size) / 2.0

	# Guarantee horizontal movement even if image fits width
	max_offset.x = max(max_offset.x, min_horizontal_padding)

func _process(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var normalized = (mouse_pos / viewport_size) * 2.0 - Vector2.ONE
	# normalized range: (-1, -1) → (1, 1)

	var desired_offset = normalized * move_strength

	# Clamp to prevent edge reveal
	desired_offset.x = clamp(desired_offset.x, -max_offset.x, max_offset.x)
	desired_offset.y = clamp(desired_offset.y, -max_offset.y, max_offset.y)

	var final_pos = -max_offset + desired_offset
	position = position.lerp(final_pos, delta * smoothness)
