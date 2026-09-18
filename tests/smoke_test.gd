extends SceneTree

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var game = scene.instantiate()
	game.suppress_disk_saves = true
	root.add_child(game)
	await process_frame

	assert(game.mode == game.Mode.LOBBY)
	assert(game.get_damage() >= 1)
	assert(game.inventory.size() <= game.MAX_INVENTORY)
	assert(game.inventory_grid.columns == 5)
	assert(game.BACKGROUND_NAMES.size() == 5)
	assert(not game.hud.has_node("BossName"))

	game.start_run()
	assert(game.level == 1)
	assert(game.level_time == 30.0)
	assert(game.boss_hp > 0.0)
	assert(game.current_background >= 0 and game.current_background < game.BACKGROUND_NAMES.size())

	game.inventory.clear()
	game.equipped.clear()
	var test_sword := {
		"id": 900001, "type": "Sword", "rarity": "Legendary", "level": 5,
		"stat": "Damage", "power": 80, "luck": 7, "sell": 16
	}
	game.inventory.append(test_sword)
	game.equipped["Sword"] = test_sword.id
	assert(game.get_damage() == 81)
	assert(game.get_luck() == 7)

	var test_armour: Dictionary = game.create_item("Epic", 5)
	assert(test_armour.power == 40)
	assert(test_armour.sell == 8)

	game.mode = game.Mode.LOBBY
	game.gold = 500
	var before_count: int = game.inventory.size()
	game.buy_crate("Epic")
	assert(game.inventory.size() == before_count + 1)
	assert(game.gold == 360)
	assert(game.inventory[-1].rarity == "Epic")
	assert(game.inventory[-1].level == game.highest_level)

	game.mode = game.Mode.RUNNING
	game.level = 37
	game.player_hp = 63.0
	game.boss_hp = 21.0
	game.level_time = 12.5
	game.current_background = 4
	game.open_pause_menu()
	assert(game.modal_open)
	assert(game.pause_screen.visible)
	game.save_and_exit_run()
	assert(game.mode == game.Mode.LOBBY)
	assert(int(game.saved_run.level) == 37)
	assert(float(game.saved_run.level_time) == 12.5)
	assert(int(game.saved_run.background) == 4)
	game.level = 1
	game.player_hp = 1.0
	game.resume_saved_run()
	assert(game.mode == game.Mode.RUNNING)
	assert(game.level == 37)
	assert(game.player_hp == 63.0)
	assert(game.boss_hp == 21.0)
	assert(game.current_background == 4)
	game.show_slot_tooltip("Helmet")
	assert(game.inventory_tooltip.visible)
	assert("HELMET SLOT" in game.inventory_tooltip_label.text)
	game.hide_inventory_tooltip()
	assert(not game.inventory_tooltip.visible)

	print("SMOKE_TEST: PASS")
	quit(0)
