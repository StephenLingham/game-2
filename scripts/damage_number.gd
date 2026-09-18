class_name DamageNumber
extends Label

var velocity := Vector2.ZERO
var life := 1.0
var max_life := 1.0

func setup(amount: int, pos: Vector2, tint: Color) -> void:
	text = str(amount)
	position = pos
	velocity = Vector2(randf_range(-60.0, 60.0), randf_range(-145.0, -95.0))
	add_theme_color_override("font_color", tint)
	add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.03, 0.85))
	add_theme_constant_override("shadow_offset_x", 3)
	add_theme_constant_override("shadow_offset_y", 3)
	add_theme_font_size_override("font_size", 28)
	custom_minimum_size = Vector2(90, 42)
	reset_size()
	pivot_offset = size * 0.5

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	velocity.y += 85.0 * delta
	position += velocity * delta
	modulate.a = clampf(life / 0.38, 0.0, 1.0)
	var pop := 1.0 + sin((max_life - life) * 8.0) * 0.08
	scale = Vector2(pop, pop)

