extends SceneTree
var game
var checks = 0
var failed = false

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed = true
		push_error(message)

func _initialize() -> void: run.call_deferred()

func find_button(parent: Node, value: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text == value: return child
		var nested = find_button(child, value)
		if nested: return nested
	return null

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.profile.data.sound = false
	game.music.stop()
	check(game.phase == "home", "Starts in polished home")
	find_button(game.modal, "달리기 시작").pressed.emit()
	check(game.phase == "run" and game.world.visible, "Play starts run")
	for stage in range(1, 31):
		var data = game.Catalog.level_data(stage)
		check(data.biome == int((stage - 1) / 5), "Five stages in each world")
		check(data.showcase >= 0 and data.showcase < 20, "Valid free showcase")
		check(data.mission in [0, 1, 2], "Mission configured")
	game.level = 1
	game.start_level()
	game.distance = 105
	game.update_run(0)
	check(game.power_id == 0 and game.showcase_taken, "First level grants free giant")
	game.clear_power()
	game.update_run(0)
	check(game.power_id == -1, "Free showcase cannot repeat")
	game.start_level()
	game.current_deal = 2
	game.show_deal()
	find_button(game.modal, "탱크 받기").pressed.emit()
	check(game.phase == "preview" and game.power_id == -1, "Reward does not arrive before preview completion")
	await create_timer(3.2).timeout
	check(game.phase == "run" and game.power_id == 2, "Completed preview grants selected power")
	game.start_level()
	game.activate_power(0)
	game.avatar.scale = Vector3.ONE * 2.8
	game.distance = 30
	game.update_run(0)
	check(game.destroyed == 2, "Giant footprint destroys both neighboring walls")
	game.start_level()
	game.activate_power(7)
	var instances = 0
	for child in game.attachments.get_children():
		if child is MultiMeshInstance3D:
			instances += 1
			check(child.multimesh.instance_count == 50, "Fifty clones use instancing")
	check(instances > 0 and instances < 20, "Clone draw count bounded")
	game.clear_power()
	game.profile.data.level = 8
	game.ui.show_map()
	check(find_button(game.modal, "8") != null, "Unlocked stage displayed")
	check(find_button(game.modal, "9") == null, "Locked stage not selectable")
	find_button(game.modal, "8").pressed.emit()
	check(game.level == 8 and game.phase == "run", "Map selects unlocked stage")
	game.ui.show_shop("home", false)
	game.profile.data.wins = 22
	game.ui.show_shop("home", false)
	find_button(game.modal, "골든 킹").pressed.emit()
	check(game.profile.data.skin == 11, "Unlocked skin selected")
	check(game.body.get_child_count() > 14, "Costume has distinct geometry")
	game.profile.data.coins = 100
	game.profile.data.upgrades = [0, 0, 0]
	game.ui.show_shop("home", true)
	find_button(game.modal, "100 코인").pressed.emit()
	check(game.profile.data.coins == 0 and game.profile.data.upgrades[0] == 1, "Upgrade spends exact price")
	game.level = 1
	game.start_level()
	game.collected = game.total_coins
	game.run_coins = 100
	game.finish(true)
	check(game.profile.data.stars.get("1") == 3, "Perfect run earns three stars")
	check(game.profile.data.coins == 205, "Mission bonus included exactly once")
	game.finish(true)
	check(game.profile.data.coins == 205, "Result cannot double grant")
	for stage in [5, 10, 15, 20, 25, 30]:
		game.level = stage
		game.start_level()
		game.start_boss()
		game.skip_deal()
		for turn in range(6):
			game.boss_clock = 3
			game.update_boss(0)
			check(game.boss_danger.size() >= 1 and game.boss_danger.size() <= 2, "Boss always leaves a free lane")
		await process_frame
	var invalid = game.profile.data.duplicate(true)
	invalid.stars = {"1": 999}
	check(not game.Profile.valid(invalid), "Invalid star count rejected")
	print("V2_TESTS_PASSED ", checks, " failed=", failed)
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit(1 if failed else 0)
