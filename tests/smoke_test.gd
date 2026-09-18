extends SceneTree

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame

	assert(game.mode == game.Mode.LOBBY)
	assert(game.get_damage() >= 1)
	assert(game.inventory.size() <= game.MAX_INVENTORY)

	game.start_run()
	assert(game.level == 1)
	assert(game.level_time == 30.0)
	assert(game.boss_hp > 0.0)

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

	print("RECTFALL_SMOKE_TEST: PASS")
	quit(0)
