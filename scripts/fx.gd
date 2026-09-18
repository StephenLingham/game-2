class_name RectFX
extends Node2D

var velocity := Vector2.ZERO
var life := 0.65
var max_life := 0.65
var rect_size := Vector2(8, 8)
var color := Color.WHITE
var spin := 0.0

func setup(pos: Vector2, vel: Vector2, tint: Color, size_value: Vector2, lifetime := 0.65) -> void:
	position = pos
	velocity = vel
	color = tint
	rect_size = size_value
	life = lifetime
	max_life = lifetime
	rotation = randf() * TAU
	spin = randf_range(-8.0, 8.0)

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	velocity.y += 170.0 * delta
	position += velocity * delta
	rotation += spin * delta
	modulate.a = clampf(life / max_life, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-rect_size * 0.5, rect_size), color)

