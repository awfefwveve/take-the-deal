extends SceneTree
var game

func _initialize() -> void:
	run.call_deferred()

func snap(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://gallery/" + name + ".png")
	print("CAPTURE ", name)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://gallery")
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.profile.data.sound = false
	game.music.stop()
	game.level = 1
	game.start_level()
	game.ui.show_home()
	game.ui.update(0.1)
	await snap("01-home")
	for zone in range(6):
		game.level = zone * 5 + 1
		game.start_level()
		game.distance = 28
		game.elapsed = 3
		game.stage_flash = 0
		game._process(0.001)
		await snap("02-world-%d" % zone)
	game.level = 1
	game.start_level()
	game.distance = 100
	game.activate_power(0)
	for i in range(40): game._process(1.0 / 60)
	await snap("03-giant")
	game.start_level()
	game.distance = 80
	game.activate_power(2)
	for i in range(30): game._process(1.0 / 60)
	await snap("04-tank")
	game.start_level()
	game.current_deal = 16
	game.show_deal()
	game.ui.update(0)
	await create_timer(0.3).timeout
	await snap("05-deal")
	game.level = 30
	game.start_level()
	game.distance = game.spec.length
	game.next_deal = game.spec.deals.size()
	game.showcase_taken = true
	game.update_run(0)
	game.skip_deal()
	game.boss_clock = 0.7
	game._process(0.001)
	await snap("06-boss")
	game.clear_power()
	game.ui.show_shop("home", false)
	game.ui.update(0)
	await snap("07-wardrobe")
	game.ui.show_shop("home", true)
	await snap("08-upgrades")
	game.ui.show_map()
	await snap("09-map")
	game.level = 1
	game.start_level()
	game.collected = 36
	game.run_coins = 72
	game.finish(true)
	game.ui.update(0)
	await create_timer(0.65).timeout
	await snap("10-result")
	game.queue_free()
	await process_frame
	quit()
