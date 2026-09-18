class_name RectFighter
extends Node2D

var is_boss := false
var body_color := Color("55d6be")
var accent_color := Color("d9fff8")
var display_name := "HERO"
var anim_time := 0.0
var attack_time := 0.0
var hurt_time := 0.0
var defeated := false
var idle_phase := 0.0

func setup(boss: bool, color: Color, title: String) -> void:
	is_boss = boss
	body_color = color
	accent_color = color.lightened(0.38)
	display_name = title
	queue_redraw()

func _ready() -> void:
	idle_phase = randf() * TAU

func attack() -> void:
	attack_time = 0.34

func hurt() -> void:
	hurt_time = 0.18

func defeat() -> void:
	defeated = true

func revive() -> void:
	defeated = false
	rotation = 0.0
	scale = Vector2.ONE
	modulate.a = 1.0

func _process(delta: float) -> void:
	anim_time += delta
	attack_time = maxf(0.0, attack_time - delta)
	hurt_time = maxf(0.0, hurt_time - delta)
	if defeated:
		rotation = lerpf(rotation, (-0.48 if is_boss else 0.48), delta * 5.0)
		scale.y = lerpf(scale.y, 0.32, delta * 5.0)
		modulate.a = lerpf(modulate.a, 0.28, delta * 2.5)
	else:
		var breathe := sin(anim_time * 3.1 + idle_phase) * 0.025
		scale.y = 1.0 + breathe
		scale.x = 1.0 - breathe
	queue_redraw()

func _draw() -> void:
	var facing := -1.0 if is_boss else 1.0
	var flash := hurt_time > 0.0 and fmod(hurt_time, 0.08) > 0.035
	var c := Color.WHITE if flash else body_color
	var dark := Color("111522")
	var reach := 30.0
	if attack_time > 0.0:
		reach += sin((0.34 - attack_time) / 0.34 * PI) * 45.0

	# Shadow, legs, body, head, eye, arms, and sword are all rectangles.
	draw_rect(Rect2(-42, 65, 84, 9), Color(0, 0, 0, 0.32))
	draw_rect(Rect2(-31, 31, 23, 38), c.darkened(0.22))
	draw_rect(Rect2(8, 31, 23, 38), c.darkened(0.30))
	draw_rect(Rect2(-38, -24, 76, 62), c)
	draw_rect(Rect2(-30, -68, 60, 46), accent_color if not flash else Color.WHITE)
	draw_rect(Rect2(12 * facing - 5, -52, 13, 9), dark)
	var attack_push := 0.0
	if is_boss and attack_time > 0.0:
		attack_push = sin((0.34 - attack_time) / 0.34 * PI) * -52.0
	draw_rect(Rect2(-57 + attack_push, -16, 19, 48), c.darkened(0.15))
	draw_rect(Rect2(38 + attack_push, -16, 19, 48), c.darkened(0.15))

	if is_boss:
		draw_rect(Rect2(-38, -80, 15, 14), c.darkened(0.35))
		draw_rect(Rect2(23, -80, 15, 14), c.darkened(0.35))
		draw_rect(Rect2(-46, -11, 92, 9), accent_color)
	else:
		var hand_x := 50.0 + reach
		draw_set_transform(Vector2(hand_x * facing, 9), attack_time * 2.0 * facing)
		draw_rect(Rect2(-4, -52, 8, 90), Color("e8edf7"))
		draw_rect(Rect2(-15, 27, 30, 7), Color("f5c451"))
		draw_set_transform(Vector2.ZERO, 0.0)
