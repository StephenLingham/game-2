extends Node2D

const RectFighterScript = preload("res://scripts/rect_fighter.gd")
const RectFXScript = preload("res://scripts/fx.gd")
const DamageNumberScript = preload("res://scripts/damage_number.gd")

enum Mode { LOBBY, RUNNING, RUN_OVER }

const MAX_LEVEL := 118
const MAX_INVENTORY := 200
const SAVE_PATH := "user://save.cfg"
const TYPES := ["Sword", "Breastplate", "Leggings", "Gauntlets", "Helmet", "Ring", "Amulet"]
const ARMOUR_TYPES := ["Breastplate", "Leggings", "Gauntlets", "Helmet"]
const RARITIES := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const RARITY_MULT := {"Common": 1, "Uncommon": 2, "Rare": 4, "Epic": 8, "Legendary": 16}
const RARITY_COLOR := {
	"Common": Color("ffffff"), "Uncommon": Color("32d45e"),
	"Rare": Color("55a7ff"), "Epic": Color("bd72ff"), "Legendary": Color("ff9f32")
}
const RARITY_TEXT_COLOR := {
	"Common": Color("233746"), "Uncommon": Color("123f24"),
	"Rare": Color("102f52"), "Epic": Color("ffffff"), "Legendary": Color("4b2600")
}
const INVENTORY_TOOLTIP_TEXT_COLOR := Color("17384a")
const CRATE_COST := {"Common": 5, "Uncommon": 16, "Rare": 48, "Epic": 140, "Legendary": 400}
const BOSS_COLORS := [Color("ef476f"), Color("ff6b35"), Color("8b5cf6"), Color("3b82f6"), Color("d946ef"), Color("f43f5e")]
const BACKGROUND_NAMES := ["Sunny Meadow"]
const ELEMENTS := [
	"Hydrogen", "Helium", "Lithium", "Beryllium", "Boron", "Carbon", "Nitrogen", "Oxygen", "Fluorine", "Neon",
	"Sodium", "Magnesium", "Aluminium", "Silicon", "Phosphorus", "Sulfur", "Chlorine", "Argon", "Potassium", "Calcium",
	"Scandium", "Titanium", "Vanadium", "Chromium", "Manganese", "Iron", "Cobalt", "Nickel", "Copper", "Zinc",
	"Gallium", "Germanium", "Arsenic", "Selenium", "Bromine", "Krypton", "Rubidium", "Strontium", "Yttrium", "Zirconium",
	"Niobium", "Molybdenum", "Technetium", "Ruthenium", "Rhodium", "Palladium", "Silver", "Cadmium", "Indium", "Tin",
	"Antimony", "Tellurium", "Iodine", "Xenon", "Caesium", "Barium", "Lanthanum", "Cerium", "Praseodymium", "Neodymium",
	"Promethium", "Samarium", "Europium", "Gadolinium", "Terbium", "Dysprosium", "Holmium", "Erbium", "Thulium", "Ytterbium",
	"Lutetium", "Hafnium", "Tantalum", "Tungsten", "Rhenium", "Osmium", "Iridium", "Platinum", "Gold", "Mercury",
	"Thallium", "Lead", "Bismuth", "Polonium", "Astatine", "Radon", "Francium", "Radium", "Actinium", "Thorium",
	"Protactinium", "Uranium", "Neptunium", "Plutonium", "Americium", "Curium", "Berkelium", "Californium", "Einsteinium", "Fermium",
	"Mendelevium", "Nobelium", "Lawrencium", "Rutherfordium", "Dubnium", "Seaborgium",
	"Bohrium", "Hassium", "Meitnerium", "Darmstadtium", "Roentgenium", "Copernicium",
	"Nihonium", "Flerovium", "Moscovium", "Livermorium", "Tennessine", "Oganesson",
]

var mode := Mode.LOBBY
var level := 1
var highest_level := 1
var highest_level_defeated := 0
var most_damage_one_hit := 0
var gold := 0
var inventory: Array[Dictionary] = []
var recently_sold: Array[Dictionary] = []
var equipped := {}
var next_item_id := 1
var selected_item_id := -1
var inventory_type_filter := "All"
var inventory_rarity_filter := "All"

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
var stats_screen: Control
var reset_confirm_screen: Control
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
var item_drop_popup: Control
var item_drop_border: ColorRect
var item_drop_inner: ColorRect
var item_drop_label: Label
var item_drop_tween: Tween
var gold_labels: Array[Label] = []
var inventory_grid: GridContainer
var inventory_type_filter_button: Button
var inventory_rarity_filter_button: Button
var inventory_type_filter_menu: Control
var inventory_rarity_filter_menu: Control
var restore_sold_button: Button
var item_details: VBoxContainer
var equipment_panel: Control
var inventory_tooltip: ColorRect
var inventory_tooltip_label: Label
var inventory_compare_label: Label
var shop_crates: VBoxContainer
var overlay_title: Label
var overlay_body: Label
var overlay_button: Button
var pause_screen: Control
var pause_title_label: Label
var resume_run_button: Button
var exit_game_button: Button
var lifetime_stats_label: Label

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
	draw_sunny_meadow_background()

func draw_gradient(top: Color, bottom: Color, height := 720, steps := 24) -> void:
	var band_height := float(height) / float(steps)
	for i in range(steps):
		draw_rect(Rect2(0, i * band_height, 1280, band_height + 1), top.lerp(bottom, float(i) / float(steps - 1)))

func draw_sunny_meadow_background() -> void:
	draw_gradient(Color("55c8ff"), Color("b9ecff"), 555, 20)
	draw_rect(Rect2(1020, 82, 112, 112), Color("ffe45c"))
	draw_rect(Rect2(1040, 102, 72, 72), Color("fff29b"))

	# Every tree is assembled from rectangular trunks and blocky clusters of leaves.
	var trees := [
		{"x": 70.0, "h": 190.0, "w": 34.0, "shape": 0},
		{"x": 190.0, "h": 280.0, "w": 42.0, "shape": 1},
		{"x": 1080.0, "h": 235.0, "w": 38.0, "shape": 2},
		{"x": 1190.0, "h": 320.0, "w": 48.0, "shape": 1},
	]
	for tree in trees:
		var trunk_x: float = tree.x
		var trunk_h: float = tree.h
		var trunk_w: float = tree.w
		var canopy_y := 548.0 - trunk_h
		draw_rect(Rect2(trunk_x, canopy_y + 82, trunk_w, trunk_h - 82), Color("a8642e"))
		draw_rect(Rect2(trunk_x + 8, canopy_y + 82, 9, trunk_h - 82), Color("d58a3d"))
		match int(tree.shape):
			0:
				draw_rect(Rect2(trunk_x - 42, canopy_y + 34, trunk_w + 84, 92), Color("31d85a"))
				draw_rect(Rect2(trunk_x - 22, canopy_y, trunk_w + 44, 50), Color("63ed72"))
			1:
				draw_rect(Rect2(trunk_x - 62, canopy_y + 56, trunk_w + 124, 68), Color("25c954"))
				draw_rect(Rect2(trunk_x - 40, canopy_y + 18, trunk_w + 80, 72), Color("4be46a"))
				draw_rect(Rect2(trunk_x - 16, canopy_y - 18, trunk_w + 32, 52), Color("79f184"))
			_:
				draw_rect(Rect2(trunk_x - 54, canopy_y + 44, trunk_w + 108, 86), Color("22c95a"))
				draw_rect(Rect2(trunk_x - 28, canopy_y + 8, trunk_w + 56, 78), Color("58e875"))
				draw_rect(Rect2(trunk_x + 5, canopy_y - 22, trunk_w + 22, 52), Color("8af58c"))

	draw_rect(Rect2(0, 548, 1280, 172), Color("39d353"))
	draw_rect(Rect2(0, 548, 1280, 14), Color("7cf36c"))
	for i in range(26):
		var patch_x := float(i * 53 - 18)
		draw_rect(Rect2(patch_x, 586 + (i % 4) * 30, 36, 9), Color("20b947"))
		draw_rect(Rect2(patch_x + 18, 574 + (i % 3) * 34, 12, 18), Color("8af56b"))

func build_world() -> void:
	player = RectFighterScript.new()
	player.position = Vector2(300, 445)
	player.setup(false, Color("38d86b"), "Player")
	add_child(player)
	boss = RectFighterScript.new()
	boss.position = Vector2(975, 445)
	boss.scale = Vector2(1.28, 1.28)
	boss.setup(true, BOSS_COLORS[0], element_name(1))
	add_child(boss)

func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 18
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("fff176")
	normal.border_color = Color("1597d4")
	normal.set_border_width_all(2)
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 11
	normal.content_margin_bottom = 11
	var hover := normal.duplicate()
	hover.bg_color = Color("a7f27b")
	hover.border_color = Color("087fbd")
	var pressed := normal.duplicate()
	pressed.bg_color = Color("64d96e")
	var disabled := normal.duplicate()
	disabled.bg_color = Color("d7e8d2")
	disabled.border_color = Color("9bb6a0")
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_color("font_color", "Button", Color("123c56"))
	t.set_color("font_hover_color", "Button", Color("0a3a25"))
	t.set_color("font_disabled_color", "Button", Color("6f8278"))
	t.set_color("font_color", "Label", Color("123c56"))
	return t

func build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	ui.add_child(build_hud())
	ui.add_child(build_lobby())
	ui.add_child(build_stats_screen())
	ui.add_child(build_reset_confirm_screen())
	ui.add_child(build_inventory())
	ui.add_child(build_shop())
	ui.add_child(build_pause_screen())
	ui.add_child(build_overlay())
	ui.add_child(build_item_drop_popup())

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
	label.add_theme_color_override("font_color", Color("123c56"))
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

	var top := panel_box(Color("eafcff"), Vector2.ZERO, Vector2(1280, 90))
	hud.add_child(top)
	level_label = title_label("Level 1 - Hydrogen", 20)
	level_label.position = Vector2(24, 18)
	level_label.size = Vector2(390, 34)
	top.add_child(level_label)
	timer_label = title_label("30.0", 28)
	timer_label.position = Vector2(565, 9)
	timer_label.size = Vector2(150, 36)
	top.add_child(timer_label)
	var timer_back := panel_box(Color("b9d9e5"), Vector2(430, 54), Vector2(420, 12))
	top.add_child(timer_back)
	timer_fill = panel_box(Color("55d6be"), Vector2.ZERO, Vector2(420, 12))
	timer_back.add_child(timer_fill)
	stats_label = Label.new()
	stats_label.position = Vector2(895, 12)
	stats_label.size = Vector2(190, 64)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(stats_label)

	var inv_btn := Button.new()
	inv_btn.text = "Inventory"
	inv_btn.position = Vector2(1096, 17)
	inv_btn.size = Vector2(160, 52)
	inv_btn.pressed.connect(open_inventory)
	top.add_child(inv_btn)

	var pbar := panel_box(Color("d9f6df"), Vector2(130, 518), Vector2(340, 24))
	hud.add_child(pbar)
	player_hp_fill = panel_box(Color("39d98a"), Vector2.ZERO, Vector2(340, 24))
	pbar.add_child(player_hp_fill)
	player_hp_label = title_label("100 / 100", 15)
	player_hp_label.position = Vector2.ZERO
	player_hp_label.size = pbar.size
	pbar.add_child(player_hp_label)

	var bbar := panel_box(Color("ffe0e4"), Vector2(810, 518), Vector2(340, 24))
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
	var shade := panel_box(Color(0.52, 0.88, 1.0, 0.94), Vector2.ZERO, Vector2(1280, 720))
	lobby.add_child(shade)
	var stripe := panel_box(Color("44d75f"), Vector2(0, 0), Vector2(22, 720))
	lobby.add_child(stripe)
	var box := panel_box(Color("f5fff0"), Vector2(330, 24), Vector2(620, 672))
	lobby.add_child(box)
	var v := VBoxContainer.new()
	v.position = Vector2(42, 88)
	v.size = Vector2(536, 520)
	v.add_theme_constant_override("separation", 12)
	box.add_child(v)
	var game_title := title_label("Elementalist", 46)
	game_title.add_theme_color_override("font_color", Color("087fbd"))
	game_title.custom_minimum_size = Vector2(0, 55)
	v.add_child(game_title)
	var start := Button.new()
	start.text = "Start Run  [Level 1]"
	start.custom_minimum_size = Vector2(0, 48)
	start.pressed.connect(start_run)
	v.add_child(start)
	resume_run_button = Button.new()
	resume_run_button.text = "Resume Saved Run"
	resume_run_button.custom_minimum_size = Vector2(0, 48)
	resume_run_button.pressed.connect(resume_saved_run)
	v.add_child(resume_run_button)
	var inv := Button.new()
	inv.text = "Inventory & Equipment"
	inv.custom_minimum_size = Vector2(0, 48)
	inv.pressed.connect(open_inventory)
	v.add_child(inv)
	var shop := Button.new()
	shop.text = "Loot Crate Shop"
	shop.custom_minimum_size = Vector2(0, 48)
	shop.pressed.connect(open_shop)
	v.add_child(shop)
	var stats := Button.new()
	stats.text = "Stats"
	stats.custom_minimum_size = Vector2(0, 48)
	stats.pressed.connect(open_stats)
	v.add_child(stats)
	var reset := Button.new()
	reset.text = "Reset All Game Data"
	reset.custom_minimum_size = Vector2(0, 48)
	reset.pressed.connect(open_reset_confirmation)
	reset.add_theme_color_override("font_color", Color("8d271f"))
	v.add_child(reset)
	exit_game_button = Button.new()
	exit_game_button.text = "Exit Game"
	exit_game_button.custom_minimum_size = Vector2(0, 48)
	exit_game_button.pressed.connect(exit_game)
	v.add_child(exit_game_button)
	return lobby

func build_stats_screen() -> Control:
	stats_screen = Control.new()
	full_rect(stats_screen)
	stats_screen.theme = make_theme()
	stats_screen.add_child(panel_box(Color(0.55, 0.9, 1.0, 0.97), Vector2.ZERO, Vector2(1280, 720)))
	var box := panel_box(Color("f5fff0"), Vector2(370, 155), Vector2(540, 410))
	stats_screen.add_child(box)
	var header := title_label("Elementalist Stats", 36)
	header.position = Vector2(30, 36)
	header.size = Vector2(480, 52)
	header.add_theme_color_override("font_color", Color("087fbd"))
	box.add_child(header)
	lifetime_stats_label = title_label("", 24)
	lifetime_stats_label.position = Vector2(45, 115)
	lifetime_stats_label.size = Vector2(450, 145)
	lifetime_stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(lifetime_stats_label)
	var close := Button.new()
	close.text = "Back to Lobby"
	close.position = Vector2(120, 305)
	close.size = Vector2(300, 58)
	close.pressed.connect(close_modal)
	box.add_child(close)
	stats_screen.visible = false
	return stats_screen

func build_reset_confirm_screen() -> Control:
	reset_confirm_screen = Control.new()
	full_rect(reset_confirm_screen)
	reset_confirm_screen.theme = make_theme()
	reset_confirm_screen.add_child(panel_box(Color(0.22, 0.55, 0.72, 0.78), Vector2.ZERO, Vector2(1280, 720)))
	var box := panel_box(Color("fffbea"), Vector2(360, 180), Vector2(560, 360))
	reset_confirm_screen.add_child(box)
	var header := title_label("Reset All Game Data?", 32)
	header.position = Vector2(30, 42)
	header.size = Vector2(500, 48)
	header.add_theme_color_override("font_color", Color("b13a2c"))
	box.add_child(header)
	var warning := title_label("This permanently clears your items, equipment, gold,\nsaved run, progress, and lifetime stats.", 18)
	warning.position = Vector2(45, 108)
	warning.size = Vector2(470, 90)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(warning)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.position = Vector2(45, 245)
	cancel.size = Vector2(220, 58)
	cancel.pressed.connect(close_modal)
	box.add_child(cancel)
	var confirm := Button.new()
	confirm.text = "Yes, Reset Everything"
	confirm.position = Vector2(295, 245)
	confirm.size = Vector2(220, 58)
	confirm.pressed.connect(reset_all_game_data)
	confirm.add_theme_color_override("font_color", Color("8d271f"))
	box.add_child(confirm)
	reset_confirm_screen.visible = false
	return reset_confirm_screen

func build_inventory() -> Control:
	inventory_screen = Control.new()
	full_rect(inventory_screen)
	inventory_screen.theme = make_theme()
	inventory_screen.add_child(panel_box(Color("dff8ff"), Vector2.ZERO, Vector2(1280, 720)))
	var header := title_label("Inventory / Equipment", 32)
	header.position = Vector2(35, 20)
	header.size = Vector2(690, 46)
	inventory_screen.add_child(header)
	inventory_count_label = Label.new()
	inventory_count_label.position = Vector2(35, 72)
	inventory_count_label.size = Vector2(1000, 32)
	inventory_count_label.add_theme_font_size_override("font_size", 14)
	inventory_screen.add_child(inventory_count_label)
	var filters := HBoxContainer.new()
	filters.position = Vector2(28, 104)
	filters.size = Vector2(700, 42)
	filters.add_theme_constant_override("separation", 10)
	inventory_screen.add_child(filters)
	var type_label := Label.new()
	type_label.text = "Item Type"
	type_label.custom_minimum_size = Vector2(82, 38)
	type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	filters.add_child(type_label)
	inventory_type_filter_button = Button.new()
	inventory_type_filter_button.custom_minimum_size = Vector2(200, 38)
	inventory_type_filter_button.text = "All Types"
	inventory_type_filter_button.pressed.connect(toggle_inventory_type_filter_menu)
	filters.add_child(inventory_type_filter_button)
	var rarity_label := Label.new()
	rarity_label.text = "Rarity"
	rarity_label.custom_minimum_size = Vector2(58, 38)
	rarity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	filters.add_child(rarity_label)
	inventory_rarity_filter_button = Button.new()
	inventory_rarity_filter_button.custom_minimum_size = Vector2(210, 38)
	inventory_rarity_filter_button.text = "All Rarities"
	inventory_rarity_filter_button.pressed.connect(toggle_inventory_rarity_filter_menu)
	filters.add_child(inventory_rarity_filter_button)
	inventory_type_filter_menu = panel_box(Color("1597d4"), Vector2(120, 144), Vector2(200, (TYPES.size() + 1) * 38 + 6))
	inventory_type_filter_menu.z_index = 150
	var type_menu_list := VBoxContainer.new()
	type_menu_list.position = Vector2(3, 3)
	type_menu_list.size = Vector2(194, (TYPES.size() + 1) * 38)
	type_menu_list.add_theme_constant_override("separation", 2)
	inventory_type_filter_menu.add_child(type_menu_list)
	var all_types_button := Button.new()
	all_types_button.text = "All Types"
	all_types_button.custom_minimum_size = Vector2(194, 36)
	all_types_button.pressed.connect(on_item_type_filter_selected.bind(0))
	type_menu_list.add_child(all_types_button)
	for i in range(TYPES.size()):
		var type_option := Button.new()
		type_option.text = TYPES[i]
		type_option.custom_minimum_size = Vector2(194, 36)
		type_option.pressed.connect(on_item_type_filter_selected.bind(i + 1))
		type_menu_list.add_child(type_option)
	inventory_screen.add_child(inventory_type_filter_menu)
	inventory_type_filter_menu.visible = false
	inventory_rarity_filter_menu = panel_box(Color("1597d4"), Vector2(398, 144), Vector2(210, (RARITIES.size() + 1) * 38 + 6))
	inventory_rarity_filter_menu.z_index = 150
	var rarity_menu_list := VBoxContainer.new()
	rarity_menu_list.position = Vector2(3, 3)
	rarity_menu_list.size = Vector2(204, (RARITIES.size() + 1) * 38)
	rarity_menu_list.add_theme_constant_override("separation", 2)
	inventory_rarity_filter_menu.add_child(rarity_menu_list)
	var all_rarities_button := Button.new()
	all_rarities_button.text = "All Rarities"
	all_rarities_button.custom_minimum_size = Vector2(204, 36)
	all_rarities_button.pressed.connect(on_inventory_rarity_filter_selected.bind(0))
	rarity_menu_list.add_child(all_rarities_button)
	for i in range(RARITIES.size()):
		var rarity_option := Button.new()
		rarity_option.text = RARITIES[i]
		rarity_option.custom_minimum_size = Vector2(204, 36)
		rarity_option.pressed.connect(on_inventory_rarity_filter_selected.bind(i + 1))
		rarity_menu_list.add_child(rarity_option)
	inventory_screen.add_child(inventory_rarity_filter_menu)
	inventory_rarity_filter_menu.visible = false
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(28, 154)
	scroll.size = Vector2(700, 529)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inventory_screen.add_child(scroll)
	inventory_grid = GridContainer.new()
	inventory_grid.columns = 5
	inventory_grid.custom_minimum_size = Vector2(675, 0)
	inventory_grid.add_theme_constant_override("h_separation", 8)
	inventory_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(inventory_grid)
	var detail_bg := panel_box(Color("f5fff0"), Vector2(755, 98), Vector2(495, 585))
	inventory_screen.add_child(detail_bg)
	var equipped_title := title_label("Equipped", 21)
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
	close.text = "Close"
	close.position = Vector2(1058, 20)
	close.size = Vector2(192, 58)
	close.pressed.connect(close_modal)
	inventory_screen.add_child(close)
	restore_sold_button = Button.new()
	restore_sold_button.position = Vector2(755, 20)
	restore_sold_button.size = Vector2(280, 58)
	restore_sold_button.pressed.connect(restore_last_sold)
	inventory_screen.add_child(restore_sold_button)
	inventory_tooltip = panel_box(Color("fff9c4"), Vector2.ZERO, Vector2(650, 196))
	inventory_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_tooltip.z_index = 100
	inventory_tooltip_label = Label.new()
	inventory_tooltip_label.position = Vector2(16, 12)
	inventory_tooltip_label.size = Vector2(294, 172)
	inventory_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_tooltip_label.add_theme_font_size_override("font_size", 15)
	inventory_tooltip.add_child(inventory_tooltip_label)
	var divider := panel_box(Color("82c9dd"), Vector2(323, 12), Vector2(3, 172))
	inventory_tooltip.add_child(divider)
	inventory_compare_label = Label.new()
	inventory_compare_label.position = Vector2(340, 12)
	inventory_compare_label.size = Vector2(294, 172)
	inventory_compare_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_compare_label.add_theme_font_size_override("font_size", 15)
	inventory_tooltip.add_child(inventory_compare_label)
	inventory_screen.add_child(inventory_tooltip)
	inventory_tooltip.visible = false
	inventory_screen.visible = false
	return inventory_screen

func add_outline_block(rect: Rect2) -> void:
	var outer := panel_box(Color("1597d4"), rect.position, rect.size)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	equipment_panel.add_child(outer)
	var inner := panel_box(Color("e8fff0"), Vector2(5, 5), rect.size - Vector2(10, 10))
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
	shop_screen.add_child(panel_box(Color("dff8ff"), Vector2.ZERO, Vector2(1280, 720)))
	var header := title_label("Loot Crate Shop", 36)
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
	close.text = "Back to Lobby"
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
	pause_screen.add_child(panel_box(Color(0.25, 0.7, 0.9, 0.72), Vector2.ZERO, Vector2(1280, 720)))
	var box := panel_box(Color("f5fff0"), Vector2(410, 200), Vector2(460, 320))
	pause_screen.add_child(box)
	pause_title_label = title_label("Paused", 36)
	pause_title_label.position = Vector2(25, 34)
	pause_title_label.size = Vector2(410, 50)
	box.add_child(pause_title_label)
	var resume := Button.new()
	resume.text = "Resume"
	resume.position = Vector2(75, 125)
	resume.size = Vector2(310, 58)
	resume.pressed.connect(close_pause_menu)
	box.add_child(resume)
	var save_exit := Button.new()
	save_exit.text = "Save & Exit to Lobby"
	save_exit.position = Vector2(75, 205)
	save_exit.size = Vector2(310, 58)
	save_exit.pressed.connect(save_and_exit_run)
	box.add_child(save_exit)
	pause_screen.visible = false
	return pause_screen

func build_overlay() -> Control:
	overlay = Control.new()
	full_rect(overlay)
	overlay.theme = make_theme()
	overlay.add_child(panel_box(Color(0.35, 0.78, 0.95, 0.9), Vector2.ZERO, Vector2(1280, 720)))
	var box := panel_box(Color("fffbea"), Vector2(390, 185), Vector2(500, 350))
	overlay.add_child(box)
	overlay_title = title_label("Run Over", 38)
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
	overlay_button.text = "Return to Lobby"
	overlay_button.position = Vector2(110, 260)
	overlay_button.size = Vector2(280, 58)
	overlay_button.pressed.connect(show_lobby)
	box.add_child(overlay_button)
	overlay.visible = false
	return overlay

func build_item_drop_popup() -> Control:
	item_drop_popup = Control.new()
	item_drop_popup.position = Vector2(340, 90)
	item_drop_popup.size = Vector2(600, 160)
	item_drop_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_drop_popup.z_index = 200
	item_drop_border = panel_box(Color("1597d4"), Vector2.ZERO, item_drop_popup.size)
	item_drop_popup.add_child(item_drop_border)
	item_drop_inner = panel_box(Color("fff9c4"), Vector2(5, 5), item_drop_popup.size - Vector2(10, 10))
	item_drop_border.add_child(item_drop_inner)
	item_drop_label = title_label("", 27)
	item_drop_label.position = Vector2(24, 18)
	item_drop_label.size = Vector2(542, 114)
	item_drop_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_drop_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_drop_inner.add_child(item_drop_label)
	item_drop_popup.pivot_offset = item_drop_popup.size * 0.5
	item_drop_popup.visible = false
	return item_drop_popup

func _process(delta: float) -> void:
	if inventory_tooltip != null and inventory_tooltip.visible:
		var mouse_pos := get_viewport().get_mouse_position() + Vector2(18, 18)
		inventory_tooltip.position = Vector2(minf(mouse_pos.x, 612.0), minf(mouse_pos.y, 506.0))
	if mode != Mode.RUNNING or modal_open:
		return
	level_time -= delta
	player_attack_clock -= delta
	boss_attack_clock -= delta
	if level_time <= 0.0:
		end_run("Time Expired", "The Level %d boss survived for 30 seconds." % level)
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
		elif inventory_screen.visible or shop_screen.visible or stats_screen.visible or reset_confirm_screen.visible:
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
		end_run("All Elements Mastered", "All 118 elemental levels have fallen. Your build is complete.")
		return
	player_max_hp = 100.0
	player_hp = player_max_hp
	# A starter can clear the first few floors; later levels demand equipment.
	boss_max_hp = round(18.0 + 2.0 * level + 0.35 * pow(level, 1.5))
	boss_hp = boss_max_hp
	level_time = 30.0
	player_attack_clock = 0.35
	boss_attack_clock = 0.85
	current_background = 0
	player.revive()
	boss.revive()
	var boss_index := (level - 1) % BOSS_COLORS.size()
	var boss_title := element_name(level)
	boss.setup(true, BOSS_COLORS[boss_index], boss_title)
	boss.scale = Vector2(1.28, 1.28)
	highest_level = maxi(highest_level, level)
	save_game()
	queue_redraw()
	update_hud()

func player_strike() -> void:
	if boss_hp <= 0.0:
		return
	var damage := get_damage()
	if damage > most_damage_one_hit:
		most_damage_one_hit = damage
		save_game()
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
		end_run("You Fell", "The Level %d boss ended this run." % level)

func boss_defeated() -> void:
	boss.defeat()
	highest_level_defeated = maxi(highest_level_defeated, level)
	for i in range(22):
		spawn_single_particle(boss.position + Vector2(randf_range(-50, 50), randf_range(-70, 40)), Vector2(randf_range(-150, 150), randf_range(-230, -50)), boss.body_color, Vector2(randf_range(5, 13), randf_range(5, 13)), 0.9)
	var reward := roll_drop()
	if inventory.size() >= MAX_INVENTORY:
		show_toast("Drop Lost - Inventory Full", Color("b52b43"))
	else:
		inventory.append(reward)
		show_item_drop(reward)
	save_game()
	level += 1
	get_tree().create_timer(1.15).timeout.connect(spawn_level)

func end_run(title: String, reason: String) -> void:
	if mode != Mode.RUNNING:
		return
	mode = Mode.RUN_OVER
	modal_open = true
	saved_run.clear()
	last_run_message = "%s\nReached Level %d. Next run starts at Level 1." % [reason, mini(level, MAX_LEVEL)]
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
	stats_screen.visible = false
	reset_confirm_screen.visible = false
	lobby.visible = true
	resume_run_button.visible = not saved_run.is_empty()
	if not saved_run.is_empty():
		resume_run_button.text = "Resume Saved Run  [Level %d]" % int(saved_run.get("level", 1))
	update_gold_labels()

func exit_game() -> void:
	get_tree().quit()

func open_stats() -> void:
	modal_open = true
	lobby.visible = false
	stats_screen.visible = true
	lifetime_stats_label.text = "Highest level defeated:  %d / %d\n%s\n\nMost damage done in one hit:  %d" % [
		highest_level_defeated,
		MAX_LEVEL,
		element_name(highest_level_defeated) if highest_level_defeated > 0 else "No elements defeated yet",
		most_damage_one_hit
	]

func open_reset_confirmation() -> void:
	modal_open = true
	lobby.visible = false
	reset_confirm_screen.visible = true

func reset_all_game_data() -> void:
	gold = 0
	highest_level = 1
	highest_level_defeated = 0
	most_damage_one_hit = 0
	next_item_id = 1
	selected_item_id = -1
	inventory.clear()
	recently_sold.clear()
	equipped.clear()
	saved_run.clear()
	level = 1
	current_background = 0
	last_run_message = "All game data has been reset."
	if not suppress_disk_saves and FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	rebuild_inventory()
	update_hud()
	show_lobby()

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
	level = clampi(int(saved_run.get("level", 1)), 1, MAX_LEVEL)
	player_hp = float(saved_run.get("player_hp", 100.0))
	player_max_hp = float(saved_run.get("player_max_hp", 100.0))
	boss_hp = float(saved_run.get("boss_hp", 1.0))
	boss_max_hp = float(saved_run.get("boss_max_hp", boss_hp))
	level_time = float(saved_run.get("level_time", 30.0))
	player_attack_clock = float(saved_run.get("player_attack_clock", 0.35))
	boss_attack_clock = float(saved_run.get("boss_attack_clock", 0.85))
	current_background = 0
	var boss_index := (level - 1) % BOSS_COLORS.size()
	var boss_title := element_name(level)
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
	show_toast("Saved Run Resumed - Level %d" % level, Color("147a58"))

func update_hud() -> void:
	level_label.text = "Level %d - %s" % [level, element_name(level)]
	timer_label.text = "%04.1f" % maxf(0.0, level_time)
	timer_fill.size.x = 420.0 * clampf(level_time / 30.0, 0.0, 1.0)
	timer_fill.color = Color("ef476f") if level_time < 8.0 else Color("55d6be")
	player_hp_fill.size.x = 340.0 * clampf(player_hp / player_max_hp, 0.0, 1.0)
	boss_hp_fill.size.x = 340.0 * clampf(boss_hp / boss_max_hp, 0.0, 1.0)
	player_hp_label.text = "%d / %d" % [ceili(player_hp), ceili(player_max_hp)]
	boss_hp_label.text = "%d / %d" % [ceili(boss_hp), ceili(boss_max_hp)]
	stats_label.text = "Damage  %d\nArmour  %d   Luck  %d" % [get_damage(), get_armour(), get_luck()]

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

func element_name(item_level: int) -> String:
	return ELEMENTS[clampi(item_level, 1, ELEMENTS.size()) - 1]

func item_display_name(item: Dictionary) -> String:
	var item_element := str(item.get("element", element_name(int(item.get("level", 1)))))
	return "%s %s %s" % [item.get("rarity", "Common"), item_element, item.get("type", "Item")]

func roll_drop() -> Dictionary:
	var luck := float(get_luck())
	var weights := [50.0 / (1.0 + luck * 0.018), 25.0, 15.0 * (1.0 + luck * 0.008), 8.0 * (1.0 + luck * 0.018), 2.0 * (1.0 + luck * 0.04)]
	var total := 0.0
	for weight in weights:
		total += weight
	var roll := randf() * total
	var cursor := 0.0
	for i in range(weights.size()):
		cursor += weights[i]
		if roll <= cursor:
			return create_item(RARITIES[i], level)
	return create_item("Common", level)

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
		"element": element_name(item_level),
		"stat": stat, "power": item_level * multiplier, "luck": luck_bonus,
		"sell": multiplier
	}
	next_item_id += 1
	return item

func open_inventory() -> void:
	modal_open = true
	lobby.visible = false
	stats_screen.visible = false
	reset_confirm_screen.visible = false
	shop_screen.visible = false
	inventory_screen.visible = true
	inventory_type_filter_menu.visible = false
	inventory_rarity_filter_menu.visible = false
	selected_item_id = inventory[0].id if not inventory.is_empty() else -1
	rebuild_inventory()

func item_matches_inventory_filters(item: Dictionary) -> bool:
	var type_matches := inventory_type_filter == "All" or str(item.get("type", "")) == inventory_type_filter
	var rarity_matches := inventory_rarity_filter == "All" or str(item.get("rarity", "")) == inventory_rarity_filter
	return type_matches and rarity_matches

func filtered_inventory_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in inventory:
		if item_matches_inventory_filters(item):
			result.append(item)
	return result

func toggle_inventory_type_filter_menu() -> void:
	inventory_type_filter_menu.visible = not inventory_type_filter_menu.visible
	inventory_rarity_filter_menu.visible = false

func toggle_inventory_rarity_filter_menu() -> void:
	inventory_rarity_filter_menu.visible = not inventory_rarity_filter_menu.visible
	inventory_type_filter_menu.visible = false

func on_item_type_filter_selected(index: int) -> void:
	inventory_type_filter = "All" if index == 0 else TYPES[index - 1]
	inventory_type_filter_button.text = "All Types" if index == 0 else inventory_type_filter
	inventory_type_filter_menu.visible = false
	rebuild_inventory()

func on_inventory_rarity_filter_selected(index: int) -> void:
	inventory_rarity_filter = "All" if index == 0 else RARITIES[index - 1]
	inventory_rarity_filter_button.text = "All Rarities" if index == 0 else inventory_rarity_filter
	inventory_rarity_filter_menu.visible = false
	rebuild_inventory()

func rebuild_inventory() -> void:
	for child in inventory_grid.get_children():
		child.queue_free()
	var filtered_items := filtered_inventory_items()
	inventory_count_label.text = "Showing %d of %d Items     %d / %d Slots     Damage %d     Armour %d     Luck %d     Gold %d" % [filtered_items.size(), inventory.size(), inventory.size(), MAX_INVENTORY, get_damage(), get_armour(), get_luck(), gold]
	var restore_cost := int(recently_sold[-1].get("sell", 0)) if not recently_sold.is_empty() else 0
	restore_sold_button.text = "Restore Last Sold (%d) - %d Gold" % [recently_sold.size(), restore_cost]
	restore_sold_button.disabled = recently_sold.is_empty() or inventory.size() >= MAX_INVENTORY or gold < restore_cost
	var selected_item := find_item(selected_item_id)
	if selected_item.is_empty() or not item_matches_inventory_filters(selected_item):
		selected_item_id = int(filtered_items[0].id) if not filtered_items.is_empty() else -1
	if inventory.is_empty():
		var empty := title_label("No Items Yet\nDefeat bosses or buy a crate.", 20)
		empty.custom_minimum_size = Vector2(665, 110)
		inventory_grid.add_child(empty)
	elif filtered_items.is_empty():
		var no_matches := title_label("No Items Match These Filters", 20)
		no_matches.custom_minimum_size = Vector2(665, 110)
		inventory_grid.add_child(no_matches)
	else:
		var sorted := filtered_items.duplicate()
		sorted.sort_custom(func(a: Dictionary, b: Dictionary):
			if is_item_equipped(int(a.id)) != is_item_equipped(int(b.id)):
				return is_item_equipped(int(a.id))
			return int(a.level) * RARITY_MULT[a.rarity] > int(b.level) * RARITY_MULT[b.rarity]
		)
		for item in sorted:
			var btn := Button.new()
			var equipped_mark := "\nEquipped" if is_item_equipped(int(item.id)) else ""
			btn.text = "%s\n%s %s\nLv.%d%s" % [item.rarity, str(item.get("element", element_name(int(item.level)))), item.type, item.level, equipped_mark]
			btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.add_theme_color_override("font_color", rarity_text_color(item.rarity))
			btn.add_theme_font_size_override("font_size", 12)
			btn.custom_minimum_size = Vector2(127, 127)
			btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			apply_rarity_style(btn, item.rarity, is_item_equipped(int(item.id)))
			btn.pressed.connect(select_item.bind(int(item.id)))
			btn.gui_input.connect(on_inventory_item_gui_input.bind(int(item.id)))
			btn.mouse_entered.connect(show_item_tooltip.bind(item))
			btn.mouse_exited.connect(hide_inventory_tooltip)
			inventory_grid.add_child(btn)
	rebuild_equipment_slots()
	rebuild_details()

func apply_rarity_style(button: Button, rarity: String, strongly_highlighted := false) -> void:
	var color: Color = RARITY_COLOR[rarity]
	var normal := StyleBoxFlat.new()
	if rarity == "Common":
		normal.bg_color = Color("ffffff")
		normal.border_color = Color("9fb3c1")
	else:
		normal.bg_color = color.darkened(0.78) if not strongly_highlighted else color.darkened(0.64)
		normal.border_color = color
	normal.set_border_width_all(4 if strongly_highlighted else 2)
	normal.content_margin_left = 5
	normal.content_margin_right = 5
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	var hover := normal.duplicate()
	hover.bg_color = Color("eaf7ff") if rarity == "Common" else color.darkened(0.52)
	hover.set_border_width_all(4)
	var pressed := normal.duplicate()
	pressed.bg_color = Color("dcecf4") if rarity == "Common" else color.darkened(0.84)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)

func rarity_text_color(rarity: String) -> Color:
	return RARITY_TEXT_COLOR.get(rarity, Color("123c56"))

func item_tooltip_text(item: Dictionary) -> String:
	var state := "Equipped" if is_item_equipped(int(item.id)) else "In Inventory"
	var luck_line := "\n+%d Luck" % int(item.luck) if int(item.luck) > 0 else ""
	return "%s\nItem Level %d  /  %s\n+%d %s%s\nSell value: %d gold" % [item_display_name(item), item.level, state, item.power, item.stat, luck_line, item.sell]

func show_item_tooltip(item: Dictionary) -> void:
	if item.is_empty():
		return
	inventory_tooltip_label.text = "Hovered Item\n\n%s" % item_tooltip_text(item)
	inventory_tooltip_label.add_theme_color_override("font_color", INVENTORY_TOOLTIP_TEXT_COLOR)
	var equipped_item := find_item(int(equipped.get(item.type, -1)))
	if equipped_item.is_empty():
		inventory_compare_label.text = "Equipped %s\n\nNothing equipped in this slot." % item.type
		inventory_compare_label.add_theme_color_override("font_color", INVENTORY_TOOLTIP_TEXT_COLOR)
	else:
		inventory_compare_label.text = "Equipped Comparison\n\n%s" % item_tooltip_text(equipped_item)
		inventory_compare_label.add_theme_color_override("font_color", INVENTORY_TOOLTIP_TEXT_COLOR)
	inventory_tooltip.visible = true

func show_slot_tooltip(slot: String) -> void:
	var item := find_item(int(equipped.get(slot, -1)))
	if item.is_empty():
		inventory_tooltip_label.text = "%s Slot\n\nNothing equipped.\nSelect a %s from the grid to equip it here." % [slot, slot]
		inventory_tooltip_label.add_theme_color_override("font_color", INVENTORY_TOOLTIP_TEXT_COLOR)
	else:
		inventory_tooltip_label.text = "Equipped Item\n\n%s" % item_tooltip_text(item)
		inventory_tooltip_label.add_theme_color_override("font_color", INVENTORY_TOOLTIP_TEXT_COLOR)
	inventory_compare_label.text = ""
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
		"Helmet": "Head", "Breastplate": "Chest", "Leggings": "Legs",
		"Gauntlets": "Hands", "Sword": "Sword", "Ring": "Ring", "Amulet": "Neck"
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
				btn.text = slot_name + "\nEmpty"
				btn.add_theme_color_override("font_color", Color("9ba9bd"))
			else:
				btn.text = "%s\n%s Lv.%d" % [slot_name, item.rarity, item.level]
				btn.add_theme_color_override("font_color", rarity_text_color(item.rarity))
				apply_rarity_style(btn, item.rarity, true)
				btn.pressed.connect(select_item.bind(int(item.id)))
			btn.mouse_entered.connect(show_slot_tooltip.bind(slot))
			btn.mouse_exited.connect(hide_inventory_tooltip)
			equipment_panel.add_child(btn)

func select_item(item_id: int) -> void:
	selected_item_id = item_id
	rebuild_details()

func on_inventory_item_gui_input(event: InputEvent, item_id: int) -> void:
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		sell_item(item_id)
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		equip_inventory_item(item_id)
		get_viewport().set_input_as_handled()

func equip_inventory_item(item_id: int) -> void:
	var item := find_item(item_id)
	if item.is_empty():
		return
	selected_item_id = item_id
	equipped[item.type] = item_id
	hide_inventory_tooltip()
	save_game()
	rebuild_inventory()
	update_hud()

func rebuild_details() -> void:
	for child in item_details.get_children():
		child.queue_free()
	var item := find_item(selected_item_id)
	if item.is_empty():
		var none := title_label("Select an Item", 22)
		item_details.add_child(none)
		return
	var name := title_label(item_display_name(item), 19)
	name.add_theme_color_override("font_color", rarity_text_color(item.rarity))
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
	equip_btn.text = "Unequip" if is_item_equipped(selected_item_id) else "Equip"
	equip_btn.custom_minimum_size = Vector2(218, 44)
	equip_btn.pressed.connect(toggle_equip_selected)
	actions.add_child(equip_btn)
	var sell_btn := Button.new()
	sell_btn.text = "Sell for %d Gold" % item.sell
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
	sell_item(selected_item_id)

func sell_item(item_id: int) -> void:
	var item := find_item(item_id)
	if item.is_empty():
		return
	var sold_copy: Dictionary = item.duplicate(true)
	sold_copy["_was_equipped"] = is_item_equipped(item_id)
	recently_sold.append(sold_copy)
	if recently_sold.size() > 5:
		recently_sold.remove_at(0)
	if is_item_equipped(item_id):
		equipped.erase(item.type)
	gold += int(item.sell)
	for i in range(inventory.size()):
		if int(inventory[i].id) == item_id:
			inventory.remove_at(i)
			break
	selected_item_id = -1
	hide_inventory_tooltip()
	save_game()
	rebuild_inventory()
	update_gold_labels()
	update_hud()

func restore_last_sold() -> void:
	if recently_sold.is_empty() or inventory.size() >= MAX_INVENTORY:
		return
	var restore_cost := int(recently_sold[-1].get("sell", 0))
	if gold < restore_cost:
		return
	var item: Dictionary = recently_sold.pop_back()
	gold -= restore_cost
	var was_equipped := bool(item.get("_was_equipped", false))
	item.erase("_was_equipped")
	inventory.append(item)
	if was_equipped and not equipped.has(item.type):
		equipped[item.type] = int(item.id)
	selected_item_id = int(item.id)
	show_toast("Restored %s" % item_display_name(item), rarity_text_color(item.rarity))
	save_game()
	rebuild_inventory()
	update_gold_labels()
	update_hud()

func open_shop() -> void:
	if mode == Mode.RUNNING:
		return
	modal_open = true
	lobby.visible = false
	stats_screen.visible = false
	reset_confirm_screen.visible = false
	inventory_screen.visible = false
	shop_screen.visible = true
	rebuild_shop()

func rebuild_shop() -> void:
	for child in shop_crates.get_children():
		child.queue_free()
	var gold_title := title_label("Gold: %d     Crate Level: %d" % [gold, highest_level], 24)
	gold_title.custom_minimum_size = Vector2(0, 45)
	shop_crates.add_child(gold_title)
	for rarity in RARITIES:
		var btn := Button.new()
		btn.text = "%s Crate     %d Gold" % [rarity, CRATE_COST[rarity]]
		btn.add_theme_color_override("font_color", rarity_text_color(rarity))
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
	show_item_drop(item)
	save_game()
	rebuild_shop()

func close_modal() -> void:
	inventory_screen.visible = false
	shop_screen.visible = false
	stats_screen.visible = false
	reset_confirm_screen.visible = false
	inventory_type_filter_menu.visible = false
	inventory_rarity_filter_menu.visible = false
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

func show_item_drop(item: Dictionary) -> void:
	if item_drop_tween != null and item_drop_tween.is_valid():
		item_drop_tween.kill()
	item_drop_label.text = "New Item\n%s" % item_display_name(item)
	var rarity_color: Color = RARITY_COLOR[item.rarity]
	item_drop_border.color = Color("9fb3c1") if item.rarity == "Common" else rarity_color.darkened(0.28)
	item_drop_inner.color = rarity_color
	item_drop_label.add_theme_color_override("font_color", rarity_text_color(item.rarity))
	item_drop_popup.visible = true
	item_drop_popup.scale = Vector2(0.9, 0.9)
	item_drop_popup.modulate.a = 0.0
	item_drop_tween = create_tween()
	item_drop_tween.tween_property(item_drop_popup, "scale", Vector2.ONE, 0.16)
	item_drop_tween.parallel().tween_property(item_drop_popup, "modulate:a", 1.0, 0.12)
	item_drop_tween.tween_interval(2.2)
	item_drop_tween.tween_property(item_drop_popup, "modulate:a", 0.0, 0.35)
	item_drop_tween.tween_callback(func(): item_drop_popup.visible = false)

func update_gold_labels() -> void:
	for label in gold_labels:
		label.text = str(gold)

func save_game() -> void:
	if suppress_disk_saves:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "gold", gold)
	cfg.set_value("meta", "highest_level", highest_level)
	cfg.set_value("meta", "highest_level_defeated", highest_level_defeated)
	cfg.set_value("meta", "most_damage_one_hit", most_damage_one_hit)
	cfg.set_value("meta", "next_item_id", next_item_id)
	cfg.set_value("items", "inventory", inventory)
	cfg.set_value("items", "equipped", equipped)
	cfg.set_value("items", "recently_sold", recently_sold)
	cfg.set_value("run", "saved", saved_run)
	cfg.save(SAVE_PATH)

func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	gold = int(cfg.get_value("meta", "gold", 0))
	highest_level = clampi(int(cfg.get_value("meta", "highest_level", 1)), 1, MAX_LEVEL)
	highest_level_defeated = clampi(int(cfg.get_value("meta", "highest_level_defeated", maxi(0, highest_level - 1))), 0, MAX_LEVEL)
	most_damage_one_hit = maxi(0, int(cfg.get_value("meta", "most_damage_one_hit", 0)))
	next_item_id = int(cfg.get_value("meta", "next_item_id", 1))
	var loaded_inventory = cfg.get_value("items", "inventory", [])
	inventory.clear()
	for value in loaded_inventory:
		if value is Dictionary and inventory.size() < MAX_INVENTORY:
			value["level"] = clampi(int(value.get("level", 1)), 1, MAX_LEVEL)
			value["element"] = element_name(int(value.level))
			inventory.append(value)
	equipped = cfg.get_value("items", "equipped", {})
	var loaded_recently_sold = cfg.get_value("items", "recently_sold", [])
	recently_sold.clear()
	for value in loaded_recently_sold:
		if value is Dictionary:
			value["level"] = clampi(int(value.get("level", 1)), 1, MAX_LEVEL)
			value["element"] = element_name(int(value.level))
			recently_sold.append(value)
	while recently_sold.size() > 5:
		recently_sold.remove_at(0)
	var loaded_run = cfg.get_value("run", "saved", {})
	saved_run = loaded_run if loaded_run is Dictionary else {}
	if not saved_run.is_empty() and int(saved_run.get("level", 1)) > MAX_LEVEL:
		saved_run.clear()
