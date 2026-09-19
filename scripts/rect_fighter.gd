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
	var dark := Color("123047")
	var attack_nudge := 0.0
	if attack_time > 0.0:
		attack_nudge = sin((0.34 - attack_time) / 0.34 * PI) * 26.0 * facing

	# Each fighter is one plain rectangular body with rectangular eyes.
	draw_rect(Rect2(-48 + attack_nudge, -72, 96, 140), c)
	var eye_x := 7.0 * facing
	draw_rect(Rect2(eye_x - 26 + attack_nudge, -38, 18, 22), Color("ffffff"))
	draw_rect(Rect2(eye_x + 8 + attack_nudge, -38, 18, 22), Color("ffffff"))
	var pupil_shift := 4.0 * facing
	draw_rect(Rect2(eye_x - 21 + pupil_shift + attack_nudge, -32, 7, 11), dark)
	draw_rect(Rect2(eye_x + 13 + pupil_shift + attack_nudge, -32, 7, 11), dark)
