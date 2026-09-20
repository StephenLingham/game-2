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
	assert(game.MAX_INVENTORY == 200)
	assert(game.MAX_LEVEL == 118)
	assert(game.ELEMENTS.size() == 118)
	assert(game.ELEMENTS[0] == "Hydrogen")
	assert(game.ELEMENTS[1] == "Helium")
	assert(game.ELEMENTS[117] == "Oganesson")
	assert(game.progression_target_gear_level(60) == 50)
	assert(game.progression_target_rarity_multiplier(60) == game.RARITY_MULT["Epic"])
	assert(game.progression_target_gear_level(118) == 113)
	assert(game.progression_target_rarity_multiplier(118) == game.RARITY_MULT["Legendary"])
	var level_60_benchmark_damage: int = 1 + game.BALANCE_DAMAGE_SLOTS * 50 * game.RARITY_MULT["Epic"]
	var final_benchmark_damage: int = 1 + game.BALANCE_DAMAGE_SLOTS * 113 * game.RARITY_MULT["Legendary"]
	assert(ceili(game.boss_health_for_level(60) / level_60_benchmark_damage) == 29)
	assert(ceili(game.boss_health_for_level(118) / final_benchmark_damage) == 30)
	assert(game.boss_health_for_level(118) > final_benchmark_damage * 29.0)
	var obsolete_final_epic_damage: int = 1 + game.BALANCE_DAMAGE_SLOTS * 108 * game.RARITY_MULT["Epic"]
	assert(game.boss_health_for_level(118) > obsolete_final_epic_damage * 30.0)
	var final_benchmark_armour: int = game.BALANCE_ARMOUR_SLOTS * 113 * game.RARITY_MULT["Legendary"]
	var final_benchmark_damage_taken: float = game.boss_damage_for_level(118) * 100.0 / (100.0 + final_benchmark_armour * 5.0)
	assert(final_benchmark_damage_taken > 3.0 and final_benchmark_damage_taken < 3.5)
	var obsolete_final_epic_armour: int = game.BALANCE_ARMOUR_SLOTS * 108 * game.RARITY_MULT["Epic"]
	var obsolete_epic_damage_taken: float = game.boss_damage_for_level(118) * 100.0 / (100.0 + obsolete_final_epic_armour * 5.0)
	assert(obsolete_epic_damage_taken > 7.0)
	assert(game.required_benchmark_hits(10) < game.required_benchmark_hits(60))
	assert(game.required_benchmark_hits(60) < game.required_benchmark_hits(117))
	assert(game.inventory_grid.columns == 4)
	game.toggle_inventory_type_filter_menu()
	assert(game.inventory_type_filter_menu.visible)
	assert(game.inventory_type_filter_menu.get_index() == game.inventory_screen.get_child_count() - 1)
	game.on_item_type_filter_selected(0)
	game.toggle_inventory_rarity_filter_menu()
	assert(game.inventory_rarity_filter_menu.visible)
	assert(game.inventory_rarity_filter_menu.get_index() == game.inventory_screen.get_child_count() - 1)
	game.on_inventory_rarity_filter_selected(0)
	assert(game.BACKGROUND_NAMES.size() == 1)
	assert(not game.hud.has_node("BossName"))
	assert(game.exit_game_button.text == "Exit Game")

	game.start_run()
	assert(game.level == 1)
	assert(game.level_time == 30.0)
	assert(game.boss_hp > 0.0)
	assert(game.current_background >= 0 and game.current_background < game.BACKGROUND_NAMES.size())
	assert(game.stats_label.text.count("\n") == 2)
	assert(game.stats_label.text.begins_with("Damage"))
	assert("\nArmour" in game.stats_label.text)
	assert("\nLuck" in game.stats_label.text)

	game.inventory.clear()
	game.recently_sold.clear()
	game.equipped.clear()
	game.most_damage_one_hit = 0
	var test_sword := {
		"id": 900001, "type": "Sword", "rarity": "Legendary", "level": 5,
		"stat": "Damage", "power": 80, "luck": 7, "sell": 16
	}
	game.inventory.append(test_sword)
	game.equipped["Sword"] = test_sword.id
	var comparison_sword := {
		"id": 900002, "type": "Sword", "rarity": "Rare", "level": 4,
		"element": "Beryllium", "stat": "Damage", "power": 16, "luck": 0, "sell": 4
	}
	game.inventory.append(comparison_sword)
	assert(game.get_damage() == 81)
	assert(game.get_luck() == 7)
	game.show_item_tooltip(comparison_sword)
	assert("Hovered Item" in game.inventory_tooltip_label.text)
	assert("Rare Beryllium Sword" in game.inventory_tooltip_label.text)
	assert("Equipped Comparison" in game.inventory_compare_label.text)
	assert("Legendary Boron Sword" in game.inventory_compare_label.text)
	assert(game.inventory_tooltip_label.get_theme_color("font_color") == game.INVENTORY_TOOLTIP_TEXT_COLOR)
	assert(game.inventory_compare_label.get_theme_color("font_color") == game.INVENTORY_TOOLTIP_TEXT_COLOR)
	game.hide_inventory_tooltip()
	game.on_item_type_filter_selected(game.TYPES.find("Sword") + 1)
	game.on_inventory_rarity_filter_selected(game.RARITIES.find("Rare") + 1)
	var filtered_items: Array[Dictionary] = game.filtered_inventory_items()
	assert(filtered_items.size() == 1)
	assert(filtered_items[0].id == comparison_sword.id)
	game.on_item_type_filter_selected(0)
	game.on_inventory_rarity_filter_selected(0)
	var comparison_button: Button
	for inventory_button in game.inventory_grid.get_children():
		if inventory_button.has_meta("inventory_item_id") and int(inventory_button.get_meta("inventory_item_id")) == int(comparison_sword.id):
			comparison_button = inventory_button
			break
	assert(comparison_button != null)
	comparison_button.pressed.emit()
	assert(int(game.equipped["Sword"]) == int(comparison_sword.id))
	assert(game.selected_item_id == comparison_sword.id)
	assert(not game.inventory_action_popup.visible)
	var gold_before_right_click_sale: int = game.gold
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	game.on_inventory_item_gui_input(right_click, comparison_sword.id)
	assert(game.find_item(comparison_sword.id).is_empty())
	assert(game.gold == gold_before_right_click_sale + int(comparison_sword.sell))
	assert(game.recently_sold.size() == 1)
	game.restore_last_sold()
	assert(not game.find_item(comparison_sword.id).is_empty())
	assert(game.recently_sold.is_empty())
	assert(game.gold == gold_before_right_click_sale)
	assert(int(game.equipped["Sword"]) == int(comparison_sword.id))
	game.equipped["Sword"] = test_sword.id
	game.boss_hp = 999.0
	game.player_strike()
	assert(game.most_damage_one_hit == 81)
	game.show_inventory_item_actions(comparison_sword.id)
	assert(game.inventory_action_popup.visible)
	assert(game.selected_item_id == comparison_sword.id)
	assert(game.inventory_action_equip_button.text == "Equip")
	assert(game.inventory_action_sell_button.text == "Sell for 4 Gold")
	game.hide_inventory_item_actions()
	assert(not game.inventory_action_popup.visible)
	game.show_inventory_item_actions(comparison_sword.id)
	game.confirm_inventory_equip_action()
	assert(not game.inventory_action_popup.visible)
	assert(int(game.equipped["Sword"]) == int(comparison_sword.id))
	game.show_inventory_item_actions(comparison_sword.id)
	assert(game.inventory_action_equip_button.text == "Unequip")
	var gold_before_sale: int = game.gold
	game.confirm_inventory_sell_action()
	assert(not game.inventory_action_popup.visible)
	assert(game.find_item(comparison_sword.id).is_empty())
	assert(game.recently_sold.size() == 1)
	game.restore_last_sold()
	assert(not game.find_item(comparison_sword.id).is_empty())
	assert(game.recently_sold.is_empty())
	assert(game.gold == gold_before_sale)
	assert(int(game.equipped["Sword"]) == int(comparison_sword.id))
	game.show_inventory_item_actions(comparison_sword.id)
	assert(game.inventory_action_popup.visible)
	assert(game.inventory_action_equip_button.text == "Unequip")
	game.confirm_inventory_equip_action()
	assert(not game.equipped.has("Sword"))
	game.show_inventory_item_actions(comparison_sword.id)
	assert(game.inventory_action_equip_button.text == "Equip")
	game.confirm_inventory_equip_action()
	assert(int(game.equipped["Sword"]) == int(comparison_sword.id))

	var common_button := Button.new()
	game.apply_rarity_style(common_button, "Common")
	assert(common_button.get_theme_stylebox("normal").bg_color == Color("ffffff"))
	common_button.free()
	game.recently_sold.clear()
	for i in range(6):
		var sold_item: Dictionary = game.create_item("Common", i + 1)
		game.inventory.append(sold_item)
		game.sell_item(int(sold_item.id))
	assert(game.recently_sold.size() == 5)

	var test_armour: Dictionary = game.create_item("Epic", 5)
	assert(test_armour.power == 40)
	assert(test_armour.sell == 8)
	assert(test_armour.element == "Boron")
	var helium_item: Dictionary = game.create_item("Legendary", 2)
	assert(game.item_display_name(helium_item).begins_with("Legendary Helium "))
	game.level = 2
	var guaranteed_drop: Dictionary = game.roll_drop()
	assert(not guaranteed_drop.is_empty())
	assert(guaranteed_drop.level == 2)
	assert(guaranteed_drop.element == "Helium")

	game.mode = game.Mode.LOBBY
	game.gold = 500
	var before_count: int = game.inventory.size()
	game.buy_crate("Epic")
	assert(game.inventory.size() == before_count + 1)
	assert(game.gold == 360)
	assert(game.inventory[-1].rarity == "Epic")
	assert(game.inventory[-1].level == game.highest_level)
	assert(game.item_drop_popup.visible)
	assert("New Item" in game.item_drop_label.text)
	assert(game.item_drop_popup.position == Vector2(340, 90))
	assert(game.item_drop_inner.color == game.RARITY_COLOR["Epic"])

	game.mode = game.Mode.RUNNING
	game.level = 37
	game.player_hp = 63.0
	game.boss_hp = 21.0
	game.level_time = 12.5
	game.current_background = 0
	game.open_pause_menu()
	assert(game.modal_open)
	assert(game.pause_screen.visible)
	assert(game.pause_title_label.text == "Paused")
	game.save_and_exit_run()
	assert(game.mode == game.Mode.LOBBY)
	assert(int(game.saved_run.level) == 37)
	assert(float(game.saved_run.level_time) == 12.5)
	assert(int(game.saved_run.background) == 0)
	game.level = 1
	game.player_hp = 1.0
	game.resume_saved_run()
	assert(game.mode == game.Mode.RUNNING)
	assert(game.level == 37)
	assert(game.player_hp == 63.0)
	assert(game.boss_hp == 21.0)
	assert(game.current_background == 0)
	game.show_slot_tooltip("Helmet")
	assert(game.inventory_tooltip.visible)
	assert("Helmet Slot" in game.inventory_tooltip_label.text)
	game.hide_inventory_tooltip()
	assert(not game.inventory_tooltip.visible)
	game.highest_level_defeated = 37
	game.open_stats()
	assert(game.stats_screen.visible)
	assert("Highest level defeated:  37 / 118" in game.lifetime_stats_label.text)
	assert("Most damage done in one hit:  81" in game.lifetime_stats_label.text)
	game.close_modal()
	game.gold = 99
	game.open_reset_confirmation()
	assert(game.reset_confirm_screen.visible)
	game.reset_all_game_data()
	assert(game.gold == 0)
	assert(game.inventory.is_empty())
	assert(game.highest_level_defeated == 0)
	assert(game.most_damage_one_hit == 0)
	assert(game.saved_run.is_empty())
	assert(game.recently_sold.is_empty())

	print("SMOKE_TEST: PASS")
	quit(0)
