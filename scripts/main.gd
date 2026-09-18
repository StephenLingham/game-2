extends Node2D

const RectFighterScript = preload("res://scripts/rect_fighter.gd")
const RectFXScript = preload("res://scripts/fx.gd")
const DamageNumberScript = preload("res://scripts/damage_number.gd")

enum Mode { LOBBY, RUNNING, RUN_OVER }

const MAX_LEVEL := 1000
const MAX_INVENTORY := 50
const SAVE_PATH := "user://rectfall_save.cfg"
const TYPES := ["Sword", "Breastplate", "Leggings", "Gauntlets", "Helmet", "Ring", "Amulet"]
const ARMOUR_TYPES := ["Breastplate", "Leggings", "Gauntlets", "Helmet"]
const RARITIES := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const RARITY_MULT := {"Common": 1, "Uncommon": 2, "Rare": 4, "Epic": 8, "Legendary": 16}
const RARITY_COLOR := {
	"Common": Color("f4f5f7"), "Uncommon": Color("66e17a"),
	"Rare": Color("55a7ff"), "Epic": Color("bd72ff"), "Legendary": Color("ff9f32")
}
const CRATE_COST := {"Common": 5, "Uncommon": 16, "Rare": 48, "Epic": 140, "Legendary": 400}
const BOSS_NAMES := ["BLOCK WARDEN", "THE RED FRAME", "NULL KNIGHT", "GRID EATER", "SQUARE ONE", "THE LAST BRICK"]
const BOSS_COLORS := [Color("ef476f"), Color("ff6b35"), Color("8b5cf6"), Color("3b82f6"), Color("d946ef"), Color("f43f5e")]
const BACKGROUND_NAMES := ["ANCIENT FOREST", "CRYSTAL FALLS", "GOLDEN DESERT", "DEEP SPACE", "LAVA FORGE"]

var mode := Mode.LOBBY
var level := 1
var highest_level := 1
var gold := 0
var inventory: Array[Dictionary] = []
var equipped := {}
var next_item_id := 1
var selected_item_id := -1

var player_hp := 100.0
var player_max_hp := 100.0
var boss_hp := 1.0
var boss_max_hp := 1.0
var level_time := 30.0
var player_attack_clock := 0.0
var boss_attack_clock := 0.0
var modal_open := false
var last_run_message := ""
var current_background := 0
var saved_run: Dictionary = {}
var suppress_disk_saves := false

# Keep scripted-node references dynamic. Referring to their `class_name` types here
# makes a fresh Godot import depend on the global script-class cache already existing.
var player
var boss
var ui: CanvasLayer
var hud: Control
var lobby: Control
var inventory_screen: Control
var shop_screen: Control
var overlay: Control
var level_label: Label
var timer_label: Label
var timer_fill: ColorRect
var player_hp_label: Label
var boss_hp_label: Label
var player_hp_fill: ColorRect
var boss_hp_fill: ColorRect
var stats_label: Label
var inventory_count_label: Label
var toast_label: Label
var lobby_message: Label
var gold_labels: Array[Label] = []
var inventory_grid: GridContainer
var item_details: VBoxContainer
var equipment_panel: Control
var inventory_tooltip: ColorRect
var inventory_tooltip_label: Label
var shop_crates: VBoxContainer
var overlay_title: Label
var overlay_body: Label
var overlay_button: Button
var pause_screen: Control
var resume_run_button: Button

func _ready() -> void:
	randomize()
	load_game()
	build_world()
	build_ui()
	show_lobby()
	var launch_args := OS.get_cmdline_user_args()
	if OS.is_debug_build() and "--qa-run" in launch_args:
		start_run()
	elif OS.is_debug_build() and "--qa-inventory" in launch_args:
		open_inventory()
	elif OS.is_debug_build() and "--qa-shop" in launch_args:
		open_shop()
	elif OS.is_debug_build() and "--qa-pause" in launch_args:
		start_run()
		open_pause_menu()
	elif OS.is_debug_build():
		for argument in launch_args:
			if argument.begins_with("--qa-background="):
				start_run()
				current_background = clampi(int(argument.trim_prefix("--qa-background=")), 0, BACKGROUND_NAMES.size() - 1)
				queue_redraw()
				break
	queue_redraw()

func _draw() -> void:
	match current_background:
		0: draw_forest_background()
		1: draw_waterfall_background()
		2: draw_desert_background()
		3: draw_space_background()
		_: draw_lava_background()

func draw_gradient(top: Color, bottom: Color, height := 720, steps := 24) -> void:
	var band_height := float(height) / float(steps)
	for i in range(steps):
		draw_rect(Rect2(0, i * band_height, 1280, band_height + 1), top.lerp(bottom, float(i) / float(steps - 1)))

func draw_forest_background() -> void:
	draw_gradient(Color("071d22"), Color("183a2b"))
	for i in range(9):
		var shaft_x := 70 + i * 158
		draw_rect(Rect2(shaft_x, 65, 28, 470), Color(0.48, 0.95, 0.69, 0.045 + (i % 3) * 0.018))
	for i in range(18):
		var x := float(i * 76 - 35)
		var trunk_w := float(24 + (i * 11) % 32)
		var trunk_h := float(260 + (i * 37) % 180)
		draw_rect(Rect2(x, 555 - trunk_h, trunk_w, trunk_h), Color("193d31"))
		draw_rect(Rect2(x + 7, 555 - trunk_h, 7, trunk_h), Color("2c6650"))
		for j in range(5):
			var leaf_x := x - 48 + ((j * 31 + i * 17) % 72)
			var leaf_y := 95 + ((j * 47 + i * 29) % 220)
			var leaf_color := Color("245d45") if (i + j) % 2 == 0 else Color("337d55")
			draw_rect(Rect2(leaf_x, leaf_y, 86 + (j % 2) * 30, 42 + (i % 3) * 11), leaf_color)
	for i in range(24):
		var moss_x := float((i * 59 + 23) % 1280)
		draw_rect(Rect2(moss_x, 520 - (i % 4) * 9, 54, 18), Color(0.33, 0.86, 0.48, 0.34))
	draw_rect(Rect2(0, 548, 1280, 172), Color("10291f"))
	draw_rect(Rect2(0, 548, 1280, 9), Color("55c879"))
	for i in range(26):
		draw_rect(Rect2(i * 51, 582 + (i % 4) * 27, 31, 8), Color("2c5b3e"))

func draw_waterfall_background() -> void:
	draw_gradient(Color("071a2c"), Color("124a59"))
	draw_rect(Rect2(0, 95, 385, 470), Color("172f3e"))
	draw_rect(Rect2(895, 95, 385, 470), Color("172f3e"))
	for i in range(8):
		draw_rect(Rect2(i * 49, 110 + (i % 3) * 54, 42, 310), Color("294c58"))
		draw_rect(Rect2(900 + i * 49, 95 + ((i + 1) % 3) * 52, 42, 330), Color("294c58"))
	for i in range(20):
		var water_color := Color("8eeaff") if i % 3 == 0 else Color("36b9d3")
		draw_rect(Rect2(385 + i * 26, 70 + (i % 4) * 8, 29, 495), water_color.darkened(float(i % 5) * 0.045))
	for i in range(22):
		var mist_x := float((i * 83 + 17) % 930 + 170)
		draw_rect(Rect2(mist_x, 500 + (i % 5) * 13, 90, 16), Color(0.72, 0.96, 1.0, 0.19))
	draw_rect(Rect2(0, 555, 1280, 165), Color("0a3442"))
	draw_rect(Rect2(0, 555, 1280, 12), Color("8de6e8"))
	for i in range(28):
		var stone := Color("345866") if i % 2 == 0 else Color("274752")
		draw_rect(Rect2(i * 49 - 20, 585 + (i % 3) * 28, 55, 19), stone)

func draw_desert_background() -> void:
	draw_gradient(Color("2b4062"), Color("e8a85c"))
	draw_rect(Rect2(930, 115, 118, 118), Color("ffd98a"))
	draw_rect(Rect2(947, 132, 84, 84), Color("fff0b5"))
	for i in range(12):
		var dune_y := 390 + i * 13
		var inset: float = absf(6.0 - float(i)) * 52.0
		draw_rect(Rect2(inset - 110, dune_y, 1490 - inset * 2, 15), Color("c8783f").lightened(float(i) * 0.018))
	for i in range(7):
		var ruin_x := 75 + i * 190
		var ruin_h := 100 + (i * 47) % 170
		draw_rect(Rect2(ruin_x, 535 - ruin_h, 38, ruin_h), Color("8d5535"))
		draw_rect(Rect2(ruin_x - 18, 535 - ruin_h, 74, 20), Color("b27245"))
	draw_rect(Rect2(0, 548, 1280, 172), Color("a96537"))
	draw_rect(Rect2(0, 548, 1280, 10), Color("f4c06c"))
	for i in range(32):
		draw_rect(Rect2(i * 43, 580 + (i % 4) * 29, 26, 6), Color("d7924d"))

func draw_space_background() -> void:
	draw_gradient(Color("030512"), Color("121238"))
	for i in range(70):
		var star_x := float((i * 197 + 31) % 1280)
		var star_y := float(98 + (i * 89) % 420)
		var star_size := float(2 + i % 5)
		var star_color := Color("b7e5ff") if i % 3 else Color("f3c6ff")
		draw_rect(Rect2(star_x, star_y, star_size, star_size), star_color)
	for i in range(12):
		draw_rect(Rect2(120 + i * 78, 170 + (i % 4) * 34, 190, 28), Color(0.42, 0.2, 0.72, 0.08))
	draw_rect(Rect2(900, 145, 210, 210), Color("271d59"))
	draw_rect(Rect2(925, 170, 160, 160), Color("493a8e"))
	draw_rect(Rect2(955, 200, 100, 100), Color("7764c5"))
	draw_rect(Rect2(0, 552, 1280, 168), Color("0c1125"))
	draw_rect(Rect2(0, 552, 1280, 8), Color("8e7cff"))
	for i in range(20):
		draw_rect(Rect2(i * 66 + 9, 594 + (i % 3) * 31, 42, 9), Color("222d55"))

func draw_lava_background() -> void:
	draw_gradient(Color("170509"), Color("5b160d"))
	for i in range(16):
		var cliff_x := float(i * 86 - 25)
		var cliff_h := float(150 + (i * 61) % 260)
		draw_rect(Rect2(cliff_x, 550 - cliff_h, 69, cliff_h), Color("211014"))
		draw_rect(Rect2(cliff_x + 11, 550 - cliff_h, 9, cliff_h), Color("4b2020"))
	for i in range(26):
		var ember_x := float((i * 137 + 19) % 1280)
		var ember_y := float(110 + (i * 73) % 410)
		draw_rect(Rect2(ember_x, ember_y, 5 + i % 6, 12 + i % 11), Color("ff7a1a"))
	draw_rect(Rect2(0, 550, 1280, 170), Color("281114"))
	draw_rect(Rect2(0, 550, 1280, 13), Color("ffb12b"))
	for i in range(22):
		var crack_x := float(i * 61 + 8)
		draw_rect(Rect2(crack_x, 575 + (i % 4) * 28, 38, 7), Color("ff4d16"))
		draw_rect(Rect2(crack_x + 15, 582 + (i % 4) * 28, 8, 24), Color("b42a13"))

func build_world() -> void:
	player = RectFighterScript.new()
	player.position = Vector2(300, 445)
	player.setup(false, Color("37c9b0"), "YOU")
	add_child(player)
	boss = RectFighterScript.new()
	boss.position = Vector2(975, 445)
	boss.scale = Vector2(1.28, 1.28)
	boss.setup(true, BOSS_COLORS[0], BOSS_NAMES[0])
	add_child(boss)

func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 18
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("222a3a")
	normal.border_color = Color("3d4962")
	normal.set_border_width_all(2)
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 11
	normal.content_margin_bottom = 11
	var hover := normal.duplicate()
	hover.bg_color = Color("34415a")
	hover.border_color = Color("66e3c4")
	var pressed := normal.duplicate()
	pressed.bg_color = Color("141a27")
	var disabled := normal.duplicate()
	disabled.bg_color = Color("151a24")
	disabled.border_color = Color("252d3c")
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_color("font_color", "Button", Color("edf2f7"))
	t.set_color("font_hover_color", "Button", Color("7fffdc"))
	return t

func build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	ui.add_child(build_hud())
	ui.add_child(build_lobby())
	ui.add_child(build_inventory())
	ui.add_child(build_shop())
	ui.add_child(build_pause_screen())
	ui.add_child(build_overlay())

	toast_label = Label.new()
	toast_label.position = Vector2(390, 625)
	toast_label.size = Vector2(500, 48)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 19)
	toast_label.add_theme_color_override("font_color", Color("ffe082"))
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(toast_label)

func full_rect(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func title_label(text_value: String, size_value := 30) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", Color("f7fafc"))
	return label

func panel_box(color: Color, pos: Vector2, box_size: Vector2) -> ColorRect:
	var panel := ColorRect.new()
	panel.color = color
	panel.position = pos
	panel.size = box_size
	return panel

func build_hud() -> Control:
	hud = Control.new()
	full_rect(hud)
	hud.theme = make_theme()

	var top := panel_box(Color("101522"), Vector2.ZERO, Vector2(1280, 90))
	hud.add_child(top)
	level_label = title_label("LEVEL 1 / 1000", 24)
	level_label.position = Vector2(32, 18)
	level_label.size = Vector2(240, 34)
	top.add_child(level_label)
	timer_label = title_label("30.0", 28)
	timer_label.position = Vector2(565, 9)
	timer_label.size = Vector2(150, 36)
	top.add_child(timer_label)
	var timer_back := panel_box(Color("262d3d"), Vector2(430, 54), Vector2(420, 12))
	top.add_child(timer_back)
	timer_fill = panel_box(Color("55d6be"), Vector2.ZERO, Vector2(420, 12))
	timer_back.add_child(timer_fill)
	stats_label = Label.new()
	stats_label.position = Vector2(895, 12)
	stats_label.size = Vector2(190, 64)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(stats_label)

	var inv_btn := Button.new()
	inv_btn.text = "INVENTORY"
	inv_btn.position = Vector2(1096, 17)
	inv_btn.size = Vector2(160, 52)
	inv_btn.pressed.connect(open_inventory)
	top.add_child(inv_btn)

	var p_name := title_label("YOU", 18)
	p_name.position = Vector2(150, 275)
	p_name.size = Vector2(300, 30)
	hud.add_child(p_name)
	var pbar := panel_box(Color("2a1820"), Vector2(130, 518), Vector2(340, 24))
	hud.add_child(pbar)
	player_hp_fill = panel_box(Color("39d98a"), Vector2.ZERO, Vector2(340, 24))
	pbar.add_child(player_hp_fill)
	player_hp_label = title_label("100 / 100", 15)
	player_hp_label.position = Vector2.ZERO
	player_hp_label.size = pbar.size
	pbar.add_child(player_hp_label)

	var bbar := panel_box(Color("2a1820"), Vector2(810, 518), Vector2(340, 24))
	hud.add_child(bbar)
	boss_hp_fill = panel_box(Color("ef476f"), Vector2.ZERO, Vector2(340, 24))
	bbar.add_child(boss_hp_fill)
	boss_hp_label = title_label("0 / 0", 15)
	boss_hp_label.position = Vector2.ZERO
	boss_hp_label.size = bbar.size
	bbar.add_child(boss_hp_label)
	hud.visible = false
	return hud

func build_lobby() -> Control:
	lobby = Control.new()
	full_rect(lobby)
	lobby.theme = make_theme()
	var shade := panel_box(Color(0.035, 0.047, 0.075, 0.95), Vector2.ZERO, Vector2(1280, 720))
	lobby.add_child(shade)
	var stripe := panel_box(Color("55d6be"), Vector2(0, 0), Vector2(22, 720))
	lobby.add_child(stripe)
	var box := panel_box(Color("111827"), Vector2(365, 70), Vector2(550, 580))
	lobby.add_child(box)
	var v := VBoxContainer.new()
	v.position = Vector2(42, 34)
	v.size = Vector2(466, 510)
	v.add_theme_constant_override("separation", 14)
	box.add_child(v)
	var game_title := title_label("RECTFALL", 52)
	game_title.add_theme_color_override("font_color", Color("70f0d2"))
	v.add_child(game_title)
	var subtitle := title_label("1000 BOSSES // ONE LIFE", 17)
	subtitle.add_theme_color_override("font_color", Color("93a4bd"))
	v.add_child(subtitle)
	lobby_message = title_label("", 18)
	lobby_message.custom_minimum_size = Vector2(0, 78)
	lobby_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lobby_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	v.add_child(lobby_message)
	var start := Button.new()
	start.text = "START RUN  [LEVEL 1]"
	start.custom_minimum_size = Vector2(0, 62)
	start.pressed.connect(start_run)
	v.add_child(start)
	resume_run_button = Button.new()
	resume_run_button.text = "RESUME SAVED RUN"
	resume_run_button.custom_minimum_size = Vector2(0, 58)
	resume_run_button.pressed.connect(resume_saved_run)
	v.add_child(resume_run_button)
	var inv := Button.new()
	inv.text = "INVENTORY & EQUIPMENT"
	inv.custom_minimum_size = Vector2(0, 56)
	inv.pressed.connect(open_inventory)
	v.add_child(inv)
	var shop := Button.new()
	shop.text = "LOOT CRATE SHOP"
	shop.custom_minimum_size = Vector2(0, 56)
	shop.pressed.connect(open_shop)
	v.add_child(shop)
	var help := Label.new()
	help.text = "Combat is automatic. Defeat each boss in 30 seconds.\nESC pauses and can save your exact run position.\nEquipment, inventory, gold, and highest level persist."
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_color_override("font_color", Color("8897ad"))
	help.add_theme_font_size_override("font_size", 15)
	v.add_child(help)
	return lobby

func build_inventory() -> Control:
	inventory_screen = Control.new()
	full_rect(inventory_screen)
	inventory_screen.theme = make_theme()
	inventory_screen.add_child(panel_box(Color(0.02, 0.027, 0.045, 0.98), Vector2.ZERO, Vector2(1280, 720)))
	var header := title_label("INVENTORY // EQUIPMENT", 32)
	header.position = Vector2(35, 20)
	header.size = Vector2(850, 46)
	inventory_screen.add_child(header)
	inventory_count_label = Label.new()
	inventory_count_label.position = Vector2(35, 72)
	inventory_count_label.size = Vector2(800, 32)
	inventory_screen.add_child(inventory_count_label)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(28, 108)
	scroll.size = Vector2(700, 575)
	inventory_screen.add_child(scroll)
	inventory_grid = GridContainer.new()
	inventory_grid.columns = 5
	inventory_grid.custom_minimum_size = Vector2(675, 0)
	inventory_grid.add_theme_constant_override("h_separation", 8)
	inventory_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(inventory_grid)
	var detail_bg := panel_box(Color("111827"), Vector2(755, 98), Vector2(495, 585))
	inventory_screen.add_child(detail_bg)
	var equipped_title := title_label("EQUIPPED", 21)
	equipped_title.position = Vector2(18, 12)
	equipped_title.size = Vector2(459, 32)
	detail_bg.add_child(equipped_title)
	equipment_panel = Control.new()
	equipment_panel.position = Vector2(15, 50)
	equipment_panel.size = Vector2(465, 385)
	detail_bg.add_child(equipment_panel)
	add_character_outline()
	item_details = VBoxContainer.new()
	item_details.position = Vector2(22, 438)
	item_details.size = Vector2(451, 130)
	item_details.add_theme_constant_override("separation", 5)
	detail_bg.add_child(item_details)
	var close := Button.new()
	close.text = "CLOSE"
	close.position = Vector2(1058, 20)
	close.size = Vector2(192, 58)
	close.pressed.connect(close_modal)
	inventory_screen.add_child(close)
	inventory_tooltip = panel_box(Color(0.035, 0.055, 0.09, 0.98), Vector2.ZERO, Vector2(310, 164))
	inventory_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_tooltip.z_index = 100
	inventory_tooltip_label = Label.new()
	inventory_tooltip_label.position = Vector2(14, 10)
	inventory_tooltip_label.size = Vector2(282, 144)
	inventory_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_tooltip_label.add_theme_font_size_override("font_size", 16)
	inventory_tooltip.add_child(inventory_tooltip_label)
	inventory_screen.add_child(inventory_tooltip)
	inventory_tooltip.visible = false
	inventory_screen.visible = false
	return inventory_screen

func add_outline_block(rect: Rect2) -> void:
	var outer := panel_box(Color("60708a"), rect.position, rect.size)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	equipment_panel.add_child(outer)
	var inner := panel_box(Color("192234"), Vector2(5, 5), rect.size - Vector2(10, 10))
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(inner)

func add_character_outline() -> void:
	add_outline_block(Rect2(193, 22, 78, 76))
	add_outline_block(Rect2(176, 104, 112, 132))
	add_outline_block(Rect2(130, 114, 38, 126))
	add_outline_block(Rect2(296, 114, 38, 126))
	add_outline_block(Rect2(183, 243, 48, 118))
	add_outline_block(Rect2(235, 243, 48, 118))

func build_shop() -> Control:
	shop_screen = Control.new()
	full_rect(shop_screen)
	shop_screen.theme = make_theme()
	shop_screen.add_child(panel_box(Color(0.02, 0.027, 0.045, 0.98), Vector2.ZERO, Vector2(1280, 720)))
	var header := title_label("LOOT CRATE SHOP", 36)
	header.position = Vector2(40, 28)
	header.size = Vector2(1200, 50)
	shop_screen.add_child(header)
	var note := title_label("Crates create a random item at your highest reached level. Exact rarity guaranteed.", 16)
	note.position = Vector2(200, 84)
	note.size = Vector2(880, 30)
	note.add_theme_color_override("font_color", Color("94a3b8"))
	shop_screen.add_child(note)
	shop_crates = VBoxContainer.new()
	shop_crates.position = Vector2(360, 135)
	shop_crates.size = Vector2(560, 455)
	shop_crates.add_theme_constant_override("separation", 10)
	shop_screen.add_child(shop_crates)
	var close := Button.new()
	close.text = "BACK TO LOBBY"
	close.position = Vector2(500, 620)
	close.size = Vector2(280, 58)
	close.pressed.connect(close_modal)
	shop_screen.add_child(close)
	shop_screen.visible = false
	return shop_screen

func build_pause_screen() -> Control:
	pause_screen = Control.new()
	full_rect(pause_screen)
	pause_screen.theme = make_theme()
	pause_screen.add_child(panel_box(Color(0.01, 0.015, 0.03, 0.78), Vector2.ZERO, Vector2(1280, 720)))
	var box := panel_box(Color("131c2e"), Vector2(410, 165), Vector2(460, 390))
	pause_screen.add_child(box)
	var title := title_label("RUN PAUSED", 36)
	title.position = Vector2(25, 36)
	title.size = Vector2(410, 50)
	box.add_child(title)
	var note := title_label("Your combat timer is frozen.\nSave & Exit stores this level, health, boss health, timer, and arena.", 17)
	note.position = Vector2(35, 98)
	note.size = Vector2(390, 90)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	var resume := Button.new()
	resume.text = "RESUME"
	resume.position = Vector2(75, 215)
	resume.size = Vector2(310, 58)
	resume.pressed.connect(close_pause_menu)
	box.add_child(resume)
	var save_exit := Button.new()
	save_exit.text = "SAVE & EXIT TO LOBBY"
	save_exit.position = Vector2(75, 292)
	save_exit.size = Vector2(310, 58)
	save_exit.pressed.connect(save_and_exit_run)
	box.add_child(save_exit)
	pause_screen.visible = false
	return pause_screen

func build_overlay() -> Control:
	overlay = Control.new()
	full_rect(overlay)
	overlay.theme = make_theme()
	overlay.add_child(panel_box(Color(0.02, 0.025, 0.04, 0.92), Vector2.ZERO, Vector2(1280, 720)))
	var box := panel_box(Color("141b2b"), Vector2(390, 185), Vector2(500, 350))
	overlay.add_child(box)
	overlay_title = title_label("RUN OVER", 38)
	overlay_title.position = Vector2(30, 40)
	overlay_title.size = Vector2(440, 52)
	box.add_child(overlay_title)
	overlay_body = title_label("", 19)
	overlay_body.position = Vector2(40, 110)
	overlay_body.size = Vector2(420, 120)
	overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(overlay_body)
	overlay_button = Button.new()
	overlay_button.text = "RETURN TO LOBBY"
	overlay_button.position = Vector2(110, 260)
	overlay_button.size = Vector2(280, 58)
	overlay_button.pressed.connect(show_lobby)
	box.add_child(overlay_button)
	overlay.visible = false
	return overlay

func _process(delta: float) -> void:
	if inventory_tooltip != null and inventory_tooltip.visible:
		var mouse_pos := get_viewport().get_mouse_position() + Vector2(18, 18)
		inventory_tooltip.position = Vector2(minf(mouse_pos.x, 958.0), minf(mouse_pos.y, 538.0))
	if mode != Mode.RUNNING or modal_open:
		return
	level_time -= delta
	player_attack_clock -= delta
	boss_attack_clock -= delta
	if level_time <= 0.0:
		end_run("TIME EXPIRED", "The Level %d boss survived for 30 seconds." % level)
		return
	if player_attack_clock <= 0.0:
		player_attack_clock += 1.0
		player_strike()
	if mode == Mode.RUNNING and boss_attack_clock <= 0.0:
		boss_attack_clock += 1.0
		boss_strike()
	update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if pause_screen.visible:
			close_pause_menu()
		elif inventory_screen.visible or shop_screen.visible:
			close_modal()
		elif mode == Mode.RUNNING:
			open_pause_menu()
		get_viewport().set_input_as_handled()

func start_run() -> void:
	mode = Mode.RUNNING
	modal_open = false
	saved_run.clear()
	level = 1
	lobby.visible = false
	overlay.visible = false
	pause_screen.visible = false
	inventory_screen.visible = false
	shop_screen.visible = false
	hud.visible = true
	spawn_level()

func spawn_level() -> void:
	if level > MAX_LEVEL:
		end_run("YOU CONQUERED RECTFALL", "All 1000 bosses have fallen. Your build is eternal.")
		return
	player_max_hp = 100.0
	player_hp = player_max_hp
	# A starter can clear the first few floors; later levels demand equipment.
	boss_max_hp = round(18.0 + 2.0 * level + 0.35 * pow(level, 1.5))
	boss_hp = boss_max_hp
	level_time = 30.0
	player_attack_clock = 0.35
	boss_attack_clock = 0.85
	var previous_background := current_background
	current_background = randi_range(0, BACKGROUND_NAMES.size() - 1)
	if level > 1 and current_background == previous_background:
		current_background = (current_background + randi_range(1, BACKGROUND_NAMES.size() - 1)) % BACKGROUND_NAMES.size()
	player.revive()
	boss.revive()
	var boss_index := (level - 1) % BOSS_NAMES.size()
	var boss_title: String = BOSS_NAMES[boss_index]
	if level % 10 == 0:
		boss_title = "ELITE " + boss_title
	boss.setup(true, BOSS_COLORS[boss_index], boss_title)
	boss.scale = Vector2(1.28, 1.28)
	highest_level = maxi(highest_level, level)
	save_game()
	show_toast("LEVEL %d // %s" % [level, BACKGROUND_NAMES[current_background]], Color("e2e8f0"))
	queue_redraw()
	update_hud()

func player_strike() -> void:
	if boss_hp <= 0.0:
		return
	var damage := get_damage()
	boss_hp = maxf(0.0, boss_hp - damage)
	player.attack()
	boss.hurt()
	spawn_damage_number(damage, boss.position + Vector2(-25, -225), RARITY_COLOR["Common"])
	spawn_impact(boss.position + Vector2(-75, -15), Color("f8fafc"), true)
	if boss_hp <= 0.0:
		boss_defeated()

func boss_strike() -> void:
	if player_hp <= 0.0 or boss_hp <= 0.0:
		return
	var raw_damage := 1.5 + level * 0.35
	var mitigated := raw_damage * (100.0 / (100.0 + get_armour() * 5.0))
	var damage := maxi(1, roundi(mitigated))
	player_hp = maxf(0.0, player_hp - damage)
	boss.attack()
	player.hurt()
	spawn_damage_number(damage, player.position + Vector2(-20, -225), Color("ff718a"))
	spawn_impact(player.position + Vector2(70, -10), Color("ef476f"), false)
	if player_hp <= 0.0:
		player.defeat()
		end_run("YOU FELL", "The Level %d boss ended this run." % level)

func boss_defeated() -> void:
	boss.defeat()
	for i in range(22):
		spawn_single_particle(boss.position + Vector2(randf_range(-50, 50), randf_range(-70, 40)), Vector2(randf_range(-150, 150), randf_range(-230, -50)), boss.body_color, Vector2(randf_range(5, 13), randf_range(5, 13)), 0.9)
	var reward := roll_drop()
	if reward.is_empty():
		show_toast("BOSS DOWN // NO ITEM DROPPED", Color("94a3b8"))
	elif inventory.size() >= MAX_INVENTORY:
		show_toast("DROP LOST // INVENTORY FULL", Color("ff718a"))
	else:
		inventory.append(reward)
		var message := "%s %s AUTO-COLLECTED" % [reward.rarity.to_upper(), reward.type.to_upper()]
		show_toast(message, RARITY_COLOR[reward.rarity])
		save_game()
	level += 1
	get_tree().create_timer(1.15).timeout.connect(spawn_level)

func end_run(title: String, reason: String) -> void:
	if mode != Mode.RUNNING:
		return
	mode = Mode.RUN_OVER
	modal_open = true
	saved_run.clear()
	last_run_message = "%s\nReached Level %d. Next run starts at Level 1." % [reason, level]
	overlay_title.text = title
	overlay_body.text = last_run_message
	overlay.visible = true
	save_game()

func show_lobby() -> void:
	mode = Mode.LOBBY
	modal_open = false
	hud.visible = false
	overlay.visible = false
	pause_screen.visible = false
	inventory_screen.visible = false
	shop_screen.visible = false
	lobby.visible = true
	lobby_message.text = last_run_message if not last_run_message.is_empty() else "Gear up, then begin at Level 1.\nHighest level reached: %d" % highest_level
	resume_run_button.visible = not saved_run.is_empty()
	if not saved_run.is_empty():
		resume_run_button.text = "RESUME SAVED RUN  [LEVEL %d]" % int(saved_run.get("level", 1))
	update_gold_labels()

func open_pause_menu() -> void:
	if mode != Mode.RUNNING:
		return
	modal_open = true
	pause_screen.visible = true
	hide_inventory_tooltip()

func close_pause_menu() -> void:
	pause_screen.visible = false
	modal_open = false

func save_run_snapshot() -> void:
	if mode != Mode.RUNNING:
		return
	saved_run = {
		"level": level,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"boss_hp": boss_hp,
		"boss_max_hp": boss_max_hp,
		"level_time": level_time,
		"player_attack_clock": player_attack_clock,
		"boss_attack_clock": boss_attack_clock,
		"background": current_background
	}

func save_and_exit_run() -> void:
	save_run_snapshot()
	save_game()
	last_run_message = "Run saved at Level %d with %.1f seconds remaining." % [level, level_time]
	show_lobby()

func resume_saved_run() -> void:
	if saved_run.is_empty():
		return
	mode = Mode.RUNNING
	modal_open = false
	level = int(saved_run.get("level", 1))
	player_hp = float(saved_run.get("player_hp", 100.0))
	player_max_hp = float(saved_run.get("player_max_hp", 100.0))
	boss_hp = float(saved_run.get("boss_hp", 1.0))
	boss_max_hp = float(saved_run.get("boss_max_hp", boss_hp))
	level_time = float(saved_run.get("level_time", 30.0))
	player_attack_clock = float(saved_run.get("player_attack_clock", 0.35))
	boss_attack_clock = float(saved_run.get("boss_attack_clock", 0.85))
	current_background = clampi(int(saved_run.get("background", 0)), 0, BACKGROUND_NAMES.size() - 1)
	var boss_index := (level - 1) % BOSS_NAMES.size()
	var boss_title: String = BOSS_NAMES[boss_index]
	if level % 10 == 0:
		boss_title = "ELITE " + boss_title
	player.revive()
	boss.revive()
	boss.setup(true, BOSS_COLORS[boss_index], boss_title)
	boss.scale = Vector2(1.28, 1.28)
	lobby.visible = false
	overlay.visible = false
	pause_screen.visible = false
	inventory_screen.visible = false
	shop_screen.visible = false
	hud.visible = true
	queue_redraw()
	update_hud()
	show_toast("SAVED RUN RESUMED // LEVEL %d" % level, Color("70f0d2"))

func update_hud() -> void:
	level_label.text = "LEVEL %d / %d" % [level, MAX_LEVEL]
	timer_label.text = "%04.1f" % maxf(0.0, level_time)
	timer_fill.size.x = 420.0 * clampf(level_time / 30.0, 0.0, 1.0)
	timer_fill.color = Color("ef476f") if level_time < 8.0 else Color("55d6be")
	player_hp_fill.size.x = 340.0 * clampf(player_hp / player_max_hp, 0.0, 1.0)
	boss_hp_fill.size.x = 340.0 * clampf(boss_hp / boss_max_hp, 0.0, 1.0)
	player_hp_label.text = "%d / %d" % [ceili(player_hp), ceili(player_max_hp)]
	boss_hp_label.text = "%d / %d" % [ceili(boss_hp), ceili(boss_max_hp)]
	stats_label.text = "DMG  %d\nARM  %d   LUCK  %d" % [get_damage(), get_armour(), get_luck()]

func spawn_damage_number(amount: int, pos: Vector2, tint: Color) -> void:
	var number = DamageNumberScript.new()
	number.setup(amount, pos, tint)
	ui.add_child(number)

func spawn_impact(pos: Vector2, tint: Color, fly_right: bool) -> void:
	for i in range(8):
		var direction := 1.0 if fly_right else -1.0
		spawn_single_particle(pos, Vector2(randf_range(40, 180) * direction, randf_range(-140, 70)), tint, Vector2(randf_range(4, 10), randf_range(3, 8)), 0.55)

func spawn_single_particle(pos: Vector2, vel: Vector2, tint: Color, particle_size: Vector2, lifetime: float) -> void:
	var particle = RectFXScript.new()
	particle.setup(pos, vel, tint, particle_size, lifetime)
	add_child(particle)

func get_damage() -> int:
	var total := 1
	for item in equipped_items():
		if item.stat == "Damage":
			total += int(item.power)
	return total

func get_armour() -> int:
	var total := 0
	for item in equipped_items():
		if item.stat == "Armour":
			total += int(item.power)
	return total

func get_luck() -> int:
	var total := 0
	for item in equipped_items():
		total += int(item.get("luck", 0))
	return total

func equipped_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot in equipped:
		var item := find_item(int(equipped[slot]))
		if not item.is_empty():
			result.append(item)
	return result

func roll_drop() -> Dictionary:
	var luck := float(get_luck())
	var weights := [50.0 / (1.0 + luck * 0.018), 20.0, 15.0 * (1.0 + luck * 0.006), 10.0 * (1.0 + luck * 0.012), 4.0 * (1.0 + luck * 0.022), 1.0 * (1.0 + luck * 0.04)]
	var total := 0.0
	for weight in weights:
		total += weight
	var roll := randf() * total
	var cursor := 0.0
	for i in range(weights.size()):
		cursor += weights[i]
		if roll <= cursor:
			if i == 0:
				return {}
			return create_item(RARITIES[i - 1], level)
	return {}

func create_item(rarity: String, item_level: int) -> Dictionary:
	var type: String = TYPES.pick_random()
	var stat := "Armour"
	if type == "Sword":
		stat = "Damage"
	elif type in ["Ring", "Amulet"]:
		stat = "Damage" if randf() < 0.5 else "Armour"
	var multiplier: int = RARITY_MULT[rarity]
	var luck_bonus := 0
	if randf() < 0.28:
		luck_bonus = maxi(1, ceili(item_level * multiplier * 0.08))
	var item := {
		"id": next_item_id, "type": type, "rarity": rarity, "level": item_level,
		"stat": stat, "power": item_level * multiplier, "luck": luck_bonus,
		"sell": multiplier
	}
	next_item_id += 1
	return item

func open_inventory() -> void:
	modal_open = true
	lobby.visible = false
	shop_screen.visible = false
	inventory_screen.visible = true
	selected_item_id = inventory[0].id if not inventory.is_empty() else -1
	rebuild_inventory()

func rebuild_inventory() -> void:
	for child in inventory_grid.get_children():
		child.queue_free()
	inventory_count_label.text = "%d / %d SLOTS     DMG %d     ARM %d     LUCK %d     GOLD %d" % [inventory.size(), MAX_INVENTORY, get_damage(), get_armour(), get_luck(), gold]
	if inventory.is_empty():
		var empty := title_label("NO ITEMS YET\nDefeat bosses or buy a crate.", 20)
		empty.custom_minimum_size = Vector2(665, 110)
		inventory_grid.add_child(empty)
	else:
		var sorted := inventory.duplicate()
		sorted.sort_custom(func(a: Dictionary, b: Dictionary):
			if is_item_equipped(int(a.id)) != is_item_equipped(int(b.id)):
				return is_item_equipped(int(a.id))
			return int(a.level) * RARITY_MULT[a.rarity] > int(b.level) * RARITY_MULT[b.rarity]
		)
		for item in sorted:
			var btn := Button.new()
			var equipped_mark := "\nEQUIPPED" if is_item_equipped(int(item.id)) else ""
			btn.text = "%s\nLv.%d %s%s" % [item.type.to_upper(), item.level, item.rarity, equipped_mark]
			btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.add_theme_color_override("font_color", RARITY_COLOR[item.rarity])
			btn.add_theme_font_size_override("font_size", 15)
			btn.custom_minimum_size = Vector2(127, 94)
			apply_rarity_style(btn, item.rarity, is_item_equipped(int(item.id)))
			btn.pressed.connect(select_item.bind(int(item.id)))
			btn.mouse_entered.connect(show_item_tooltip.bind(item))
			btn.mouse_exited.connect(hide_inventory_tooltip)
			inventory_grid.add_child(btn)
	rebuild_equipment_slots()
	rebuild_details()

func apply_rarity_style(button: Button, rarity: String, strongly_highlighted := false) -> void:
	var color: Color = RARITY_COLOR[rarity]
	var normal := StyleBoxFlat.new()
	normal.bg_color = color.darkened(0.78) if not strongly_highlighted else color.darkened(0.64)
	normal.border_color = color
	normal.set_border_width_all(4 if strongly_highlighted else 2)
	normal.content_margin_left = 5
	normal.content_margin_right = 5
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	var hover := normal.duplicate()
	hover.bg_color = color.darkened(0.52)
	hover.set_border_width_all(4)
	var pressed := normal.duplicate()
	pressed.bg_color = color.darkened(0.84)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)

func item_tooltip_text(item: Dictionary) -> String:
	var state := "EQUIPPED" if is_item_equipped(int(item.id)) else "IN INVENTORY"
	var luck_line := "\n+%d Luck" % int(item.luck) if int(item.luck) > 0 else ""
	return "%s %s\nItem Level %d  //  %s\n+%d %s%s\nSell value: %d gold" % [item.rarity.to_upper(), item.type.to_upper(), item.level, state, item.power, item.stat, luck_line, item.sell]

func show_item_tooltip(item: Dictionary) -> void:
	if item.is_empty():
		return
	inventory_tooltip_label.text = item_tooltip_text(item)
	inventory_tooltip_label.add_theme_color_override("font_color", RARITY_COLOR[item.rarity])
	inventory_tooltip.visible = true

func show_slot_tooltip(slot: String) -> void:
	var item := find_item(int(equipped.get(slot, -1)))
	if item.is_empty():
		inventory_tooltip_label.text = "%s SLOT\nNothing equipped.\nSelect a %s from the grid to equip it here." % [slot.to_upper(), slot]
		inventory_tooltip_label.add_theme_color_override("font_color", Color("a9b6ca"))
	else:
		inventory_tooltip_label.text = item_tooltip_text(item)
		inventory_tooltip_label.add_theme_color_override("font_color", RARITY_COLOR[item.rarity])
	inventory_tooltip.visible = true

func hide_inventory_tooltip() -> void:
	if inventory_tooltip != null:
		inventory_tooltip.visible = false

func rebuild_equipment_slots() -> void:
	for child in equipment_panel.get_children():
		if child.has_meta("equipment_slot"):
			child.queue_free()
	var slot_rects := {
		"Helmet": [Rect2(183, 12, 98, 96)],
		"Breastplate": [Rect2(166, 102, 132, 139)],
		"Leggings": [Rect2(173, 239, 121, 129)],
		"Gauntlets": [Rect2(116, 122, 50, 116), Rect2(298, 122, 50, 116)],
		"Sword": [Rect2(355, 116, 90, 188)],
		"Ring": [Rect2(22, 250, 88, 62)],
		"Amulet": [Rect2(18, 50, 104, 72)]
	}
	var display_names := {
		"Helmet": "HEAD", "Breastplate": "CHEST", "Leggings": "LEGS",
		"Gauntlets": "HANDS", "Sword": "SWORD", "Ring": "RING", "Amulet": "NECK"
	}
	for slot in slot_rects:
		var item := find_item(int(equipped.get(slot, -1)))
		var slot_name: String = display_names[slot]
		for rect in slot_rects[slot]:
			var btn := Button.new()
			btn.set_meta("equipment_slot", slot)
			btn.position = rect.position
			btn.size = rect.size
			btn.add_theme_font_size_override("font_size", 12)
			if item.is_empty():
				btn.text = slot_name + "\nEMPTY"
				btn.add_theme_color_override("font_color", Color("9ba9bd"))
			else:
				btn.text = "%s\n%s Lv.%d" % [slot_name, item.rarity, item.level]
				btn.add_theme_color_override("font_color", RARITY_COLOR[item.rarity])
				apply_rarity_style(btn, item.rarity, true)
				btn.pressed.connect(select_item.bind(int(item.id)))
			btn.mouse_entered.connect(show_slot_tooltip.bind(slot))
			btn.mouse_exited.connect(hide_inventory_tooltip)
			equipment_panel.add_child(btn)

func select_item(item_id: int) -> void:
	selected_item_id = item_id
	rebuild_details()

func rebuild_details() -> void:
	for child in item_details.get_children():
		child.queue_free()
	var item := find_item(selected_item_id)
	if item.is_empty():
		var none := title_label("SELECT AN ITEM", 22)
		item_details.add_child(none)
		return
	var name := title_label("%s %s" % [item.rarity.to_upper(), item.type.to_upper()], 19)
	name.add_theme_color_override("font_color", RARITY_COLOR[item.rarity])
	item_details.add_child(name)
	var desc := Label.new()
	desc.text = "Lv.%d   +%d %s   +%d Luck   Sell: %d gold" % [item.level, item.power, item.stat, item.luck, item.sell]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 15)
	desc.custom_minimum_size = Vector2(0, 24)
	item_details.add_child(desc)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	item_details.add_child(actions)
	var equip_btn := Button.new()
	equip_btn.text = "UNEQUIP" if is_item_equipped(selected_item_id) else "EQUIP"
	equip_btn.custom_minimum_size = Vector2(218, 44)
	equip_btn.pressed.connect(toggle_equip_selected)
	actions.add_child(equip_btn)
	var sell_btn := Button.new()
	sell_btn.text = "SELL FOR %d GOLD" % item.sell
	sell_btn.custom_minimum_size = Vector2(218, 44)
	sell_btn.pressed.connect(sell_selected)
	actions.add_child(sell_btn)

func toggle_equip_selected() -> void:
	var item := find_item(selected_item_id)
	if item.is_empty():
		return
	if is_item_equipped(selected_item_id):
		equipped.erase(item.type)
	else:
		equipped[item.type] = selected_item_id
	save_game()
	rebuild_inventory()
	update_hud()

func sell_selected() -> void:
	var item := find_item(selected_item_id)
	if item.is_empty():
		return
	if is_item_equipped(selected_item_id):
		equipped.erase(item.type)
	gold += int(item.sell)
	for i in range(inventory.size()):
		if int(inventory[i].id) == selected_item_id:
			inventory.remove_at(i)
			break
	selected_item_id = inventory[0].id if not inventory.is_empty() else -1
	save_game()
	rebuild_inventory()
	update_gold_labels()

func open_shop() -> void:
	if mode == Mode.RUNNING:
		return
	modal_open = true
	lobby.visible = false
	inventory_screen.visible = false
	shop_screen.visible = true
	rebuild_shop()

func rebuild_shop() -> void:
	for child in shop_crates.get_children():
		child.queue_free()
	var gold_title := title_label("GOLD: %d     CRATE LEVEL: %d" % [gold, highest_level], 24)
	gold_title.custom_minimum_size = Vector2(0, 45)
	shop_crates.add_child(gold_title)
	for rarity in RARITIES:
		var btn := Button.new()
		btn.text = "%s CRATE     %d GOLD" % [rarity.to_upper(), CRATE_COST[rarity]]
		btn.add_theme_color_override("font_color", RARITY_COLOR[rarity])
		btn.custom_minimum_size = Vector2(0, 64)
		btn.disabled = gold < int(CRATE_COST[rarity]) or inventory.size() >= MAX_INVENTORY
		btn.pressed.connect(buy_crate.bind(rarity))
		shop_crates.add_child(btn)

func buy_crate(rarity: String) -> void:
	var cost: int = CRATE_COST[rarity]
	if gold < cost or inventory.size() >= MAX_INVENTORY:
		return
	gold -= cost
	var item := create_item(rarity, highest_level)
	inventory.append(item)
	show_toast("%s %s FOUND" % [rarity.to_upper(), item.type.to_upper()], RARITY_COLOR[rarity])
	save_game()
	rebuild_shop()

func close_modal() -> void:
	inventory_screen.visible = false
	shop_screen.visible = false
	hide_inventory_tooltip()
	modal_open = false
	if mode == Mode.RUNNING:
		hud.visible = true
	else:
		show_lobby()

func find_item(item_id: int) -> Dictionary:
	for item in inventory:
		if int(item.id) == item_id:
			return item
	return {}

func is_item_equipped(item_id: int) -> bool:
	for slot in equipped:
		if int(equipped[slot]) == item_id:
			return true
	return false

func show_toast(message: String, tint: Color) -> void:
	toast_label.text = message
	toast_label.add_theme_color_override("font_color", tint)
	toast_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.5)

func update_gold_labels() -> void:
	for label in gold_labels:
		label.text = str(gold)

func save_game() -> void:
	if suppress_disk_saves:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "gold", gold)
	cfg.set_value("meta", "highest_level", highest_level)
	cfg.set_value("meta", "next_item_id", next_item_id)
	cfg.set_value("items", "inventory", inventory)
	cfg.set_value("items", "equipped", equipped)
	cfg.set_value("run", "saved", saved_run)
	cfg.save(SAVE_PATH)

func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	gold = int(cfg.get_value("meta", "gold", 0))
	highest_level = int(cfg.get_value("meta", "highest_level", 1))
	next_item_id = int(cfg.get_value("meta", "next_item_id", 1))
	var loaded_inventory = cfg.get_value("items", "inventory", [])
	inventory.clear()
	for value in loaded_inventory:
		if value is Dictionary:
			inventory.append(value)
	equipped = cfg.get_value("items", "equipped", {})
	var loaded_run = cfg.get_value("run", "saved", {})
	saved_run = loaded_run if loaded_run is Dictionary else {}
