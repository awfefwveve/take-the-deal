extends SceneTree

var failed = false
var checks = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.profile.data.sound = false
	for id in range(20):
		game.level = 2
		game.start_level()
		await process_frame
		game.activate_power(id)
		check(game.power_id == id and game.power_left == 8, "Power activates: %d" % id)
		for frame in range(12): game._process(1.0 / 60)
		check(game.power_left < 8 and game.power_left > 7, "Power ticks: %d" % id)
		game.power_left = 0.001
		game._process(1.0 / 60)
		check(game.power_id == -1, "Power expires: %d" % id)
		await process_frame
	game.level = 1
	game.start_level()
	game.damage()
	game.damage()
	check(game.hp == 2, "Invulnerability prevents double damage")
	var start_coins = game.profile.data.coins
	game.finish(true)
	var payout = game.profile.data.coins
	game.finish(true)
	check(payout == start_coins + 75 and game.profile.data.coins == payout, "Result reward is idempotent")
	game.start_level()
	game.pause_game()
	var before = game.distance
	game._process(0.05)
	check(game.distance == before, "Pause freezes gameplay")
	game.start_level()
	game.current_deal = 2
	game.show_deal()
	game._process(0.05)
	check(game.distance == 0 and game.phase == "deal", "Deal freezes gameplay")
	game.skip_deal()
	check(game.phase == "run" and game.power_id == -1, "Skipping does not grant power")
	game.show_deal()
	game.preview_reward()
	check(game.power_id == -1 and game.phase == "preview", "Preview cannot reward early")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.rewards.pending.is_empty() and game.phase == "pause", "Focus loss cancels preview and pauses")
	await create_timer(3.2).timeout
	check(game.power_id == -1, "Late preview callback cannot reward")
	for stage in [5, 10, 15, 20, 25, 30]:
		game.level = stage
		game.start_level()
		game.start_boss()
		game.skip_deal()
		check(game.boss != null and game.boss_hp > 0, "Boss builds: %d" % stage)
		await process_frame
	print("GAME_TESTS_PASSED ", checks, " failed=", failed)
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
