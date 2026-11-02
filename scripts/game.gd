extends Node3D

const Catalog = preload("res://scripts/catalog.gd")
const Profile = preload("res://scripts/profile.gd")
const RewardGate = preload("res://scripts/reward_gate.gd")
const Art = preload("res://scripts/art.gd")
const Interface = preload("res://scripts/interface.gd")
const LIME = Color("ffc954")
const INK = Color("1b1434")
const CORAL = Color("ff7652")
var profile = Profile.new()
var rewards = RewardGate.new()
var level = 1
var spec: Dictionary
var phase = "run"
var distance = 0.0
var elapsed = 0.0
var run_coins = 0
var hp = 3
var target_x = 0.0
var invulnerable = 0.0
var small = false
var power_id = -1
var power_left = 0.0
var next_deal = 0
var current_deal = 0
var boss_hp = 10.0
var boss_clock = 0.0
var boss_lane = 1
var boss_hit = false
var strike_cooldown = 0.0
var finished = false
var drag = false
var drag_x = 0.0
var drag_start = 0.0
var shake = 0.0
var world: Node3D
var avatar: Node3D
var body: Node3D
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D
var camera: Camera3D
var boss: Node3D
var boss_warning: MeshInstance3D
var attachments: Node3D
var rows: Array = []
var particles: Array = []
var coins: Array = []
var scenery: Array = []
var materials = {}
var hud: Control
var modal: Control
var stats: Label
var caption: Label
var banner: Label
var bar: ProgressBar
var power_label: Label
var shrink_button: Button
var pause_button: Button
var boss_bar: ProgressBar
var audio_player: AudioStreamPlayer
var automation = false
var screen_at = -1.0
var session_started = 0
var art
var ui
var combo = 0
var combo_timer = 0.0
var destroyed = 0
var collected = 0
var total_coins = 0
var hit_count = 0
var showcase_taken = false
var showcase_orb: Node3D
var hit_stop = 0.0
var boss_danger: Array = [1]
var boss_turn = 0
var boss_warning2: MeshInstance3D
var auto_powers = false
var force_run = false
var capture_mode = "run"
var world_time = 0.0
var music: AudioStreamPlayer
var sound_cache = {}
var stage_flash = 0.0

func _ready() -> void:
	profile.load_profile()
	level = int(profile.data.level)
	for arg in OS.get_cmdline_user_args():
		if arg == "--autoplay": automation = true
		if arg == "--powers": auto_powers = true
		if arg.begins_with("--level="):
			level = maxi(1, int(arg.split("=")[1]))
			force_run = true
		if arg.begins_with("--screenshot="): screen_at = float(arg.split("=")[1])
		if arg.begins_with("--capture-mode="): capture_mode = arg.split("=")[1]
	art = Art.new(self)
	ui = Interface.new(self)
	build_scene()
	build_ui()
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	build_music()
	session_started = Time.get_ticks_msec()
	track("session_start")
	track("game_start")
	start_level()
	if not automation and not force_run: ui.show_home()
	if capture_mode == "home": ui.show_home()
	if capture_mode == "shop": ui.show_shop("home", false)
	if capture_mode == "map": ui.show_map()
	if not profile.warning.is_empty(): caption.text = profile.warning

func material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var key = color.to_html() + str(glow)
	if materials.has(key): return materials[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	m.metallic_specular = 0.12
	if glow:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 0.5
	materials[key] = m
	return m

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var shape = BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func sphere(parent: Node3D, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var shape = SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2
	shape.radial_segments = 10
	shape.rings = 5
	mesh.mesh = shape
	mesh.material_override = material(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func character(parent: Node3D, color: Color) -> Node3D:
	return art.character(parent, color)

func build_scene() -> void:
	art.build_environment()
	camera = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, 10, 13)
	camera.look_at(Vector3(0, 0, -9))
	camera.fov = 49
	world = Node3D.new()
	add_child(world)
	avatar = Node3D.new()
	add_child(avatar)
	rebuild_avatar()

func rebuild_avatar() -> void:
	for child in avatar.get_children():
		avatar.remove_child(child)
		child.queue_free()
	body = art.character(avatar, Color(Catalog.COLORS[int(profile.data.skin)]), int(profile.data.skin))
	left_leg = body.get_child(7)
	right_leg = body.get_child(8)
	attachments = Node3D.new()
	avatar.add_child(attachments)

func panel_style(color: Color, radius: int = 20) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

func label_at(parent: Control, text: String, pos: Vector2, size: Vector2, font_size: int, color: Color = Color.WHITE) -> Label:
	return ui.text(parent, text, pos, size, font_size, ui.INK if color == Color.WHITE else color)

func button_at(parent: Control, text: String, pos: Vector2, size: Vector2, action: Callable, bright: bool = false) -> Button:
	return ui.button(parent, text, pos, size, action, bright)

func build_ui() -> void:
	ui.build()

func clear_modal() -> void:
	for child in modal.get_children():
		modal.remove_child(child)
		child.queue_free()
	modal.hide()

func card(title: String, subtitle: String) -> Control:
	return ui.sheet(title, subtitle, 325, 490)

func start_level() -> void:
	clear_modal()
	for child in world.get_children():
		world.remove_child(child)
		child.queue_free()
	for p in particles:
		if is_instance_valid(p.node): p.node.queue_free()
	particles.clear()
	rows.clear()
	coins.clear()
	world.show()
	camera.position = Vector3(0, 10, 13)
	camera.look_at(Vector3(0, 0, -9))
	camera.fov = 49
	combo = 0
	combo_timer = 0
	destroyed = 0
	collected = 0
	hit_count = 0
	hit_stop = 0
	showcase_taken = false
	boss_danger = [1]
	boss_turn = 0
	distance = 0
	elapsed = 0
	run_coins = 0
	hp = 3
	target_x = 0
	avatar.position = Vector3.ZERO
	avatar.scale = Vector3.ONE
	invulnerable = 0
	power_id = -1
	power_left = 0
	power_label.text = ""
	next_deal = 0
	finished = false
	small = false
	boss = null
	boss_bar.hide()
	phase = "run"
	rebuild_avatar()
	spec = Catalog.level_data(level)
	art.set_biome(spec.biome)
	for row in spec.rows: spawn_row(row)
	var finish = Node3D.new()
	world.add_child(finish)
	finish.position.z = -spec.length
	box(finish, Vector3(-4.1, 2, 0), Vector3(0.25, 4, 0.25), LIME)
	box(finish, Vector3(4.1, 2, 0), Vector3(0.25, 4, 0.25), LIME)
	box(finish, Vector3(0, 4, 0), Vector3(8.4, 0.55, 0.3), LIME)
	finish.set_meta("distance", spec.length)
	total_coins = coins.size()
	showcase_orb = Node3D.new()
	world.add_child(showcase_orb)
	showcase_orb.set_meta("distance", spec.showcase_distance)
	showcase_orb.position = Vector3(0, 1.0, -spec.showcase_distance)
	art.ring(showcase_orb, Vector3.ZERO, 0.58, 0.09, Color("ffb953")).rotation.x = PI / 2
	box(showcase_orb, Vector3.ZERO, Vector3(0.48, 0.6, 0.48), Color("fff1a2")).rotation.z = 0.2
	# Checkerboard and side flags make the finish line recognizable at speed.
	for x in range(12):
		for z in range(2): box(finish, Vector3(-3.85 + x * 0.7, 0.022, z * 0.7), Vector3(0.7, 0.04, 0.7), Color.WHITE if (x + z) % 2 == 0 else Color("39586b"))
	banner.text = Catalog.WORLDS[spec.biome].name
	caption.text = "좌우로 드래그해서 출발!" if level == 1 else "코인을 따라 달려봐요"
	stage_flash = 2.8
	track("level_start")
	ui.update(0)

func spawn_row(row: Dictionary) -> void:
	var root = Node3D.new()
	world.add_child(root)
	root.position.z = -row.distance
	var blocks: Array = []
	for lane in range(3):
		var x = (lane - 1) * 2.8
		if lane == int(row.safe):
			for side in [-1, 1]:
				var arrow = box(root, Vector3(x + side * 0.23, 0.02, -0.2), Vector3(0.1, 0.025, 0.62), Color("75c7a8"))
				arrow.rotation.y = side * -0.6
			for j in range(3):
				var c = art.coin(root, Vector3(x, 0.85, -2.0 + j * 2))
				coins.append({"node": c, "distance": row.distance + 2.0 - j * 2, "x": x, "taken": false})
			continue
		var obstacle = Node3D.new()
		root.add_child(obstacle)
		obstacle.position.x = x
		match row.kind:
			"crowd":
				for j in range(3):
					var enemy = character(obstacle, Color("f68176"))
					enemy.position = Vector3((j - 1) * 0.65, 0, abs(j - 1) * -0.65)
					enemy.scale = Vector3.ONE * 0.65
					enemy.rotation.y = PI
			"laser", "spinner":
				box(obstacle, Vector3(0, 0.85, 0), Vector3(2.5, 0.18, 0.18), Color("ff4a85"))
				for side in [-1, 1]: box(obstacle, Vector3(side * 1.12, 0.8, 0), Vector3(0.2, 1.6, 0.5), INK)
			"car":
				box(obstacle, Vector3(0, 0.65, 0), Vector3(2.1, 0.8, 2.7), Color("ffca67"))
				box(obstacle, Vector3(0, 1.3, -0.2), Vector3(1.7, 0.7, 1.3), Color("85bdd4"))
				for side in [-1, 1]:
					for z in [-0.8, 0.8]: sphere(obstacle, Vector3(side * 1.0, 0.35, z), 0.33, INK)
			"bridge", "water", "fire":
				box(obstacle, Vector3(0, 0.04, 0), Vector3(2.75, 0.1, 4), Color("271833") if row.kind == "bridge" else (Color("48a6d0") if row.kind == "water" else CORAL))
				if row.kind == "fire":
					for j in range(3):
						art.cylinder(obstacle, Vector3(j * 0.7 - 0.7, 0.6, 0), 0.42, 1.2, Color("ff9b42"), 0)
						art.cylinder(obstacle, Vector3(j * 0.7 - 0.7, 0.32, 0.24), 0.22, 0.62, Color("ffe078"), 0)
			"ball": sphere(obstacle, Vector3(0, 1.05, 0), 1.0, CORAL)
			"crusher":
				box(obstacle, Vector3(0, 0.55, 0), Vector3(2.3, 1.1, 0.9), Color("758c9b"))
				box(obstacle, Vector3(0, 1.1, 0), Vector3(2.45, 0.18, 1.05), Color("ffc867"))
				for j in range(5):
					var tooth = art.cylinder(obstacle, Vector3(-0.85 + j * 0.43, -0.1, 0), 0.16, 0.45, Color("d0dce1"), 0)
					tooth.rotation.z = PI
				for side in [-1, 1]: box(root, Vector3(x + side * 1.18, 1.7, 0.4), Vector3(0.1, 3.4, 0.15), Color("829da4"))
			"hole", "gate":
				box(obstacle, Vector3(0, 1.6, 0), Vector3(2.5, 1.6, 0.65), Color("ef986f"))
				for side in [-1, 1]: box(obstacle, Vector3(side * 1.05, 0.5, 0), Vector3(0.4, 1, 0.65), Color("ef986f"))
			_:
				for y in range(3):
					for b in range(3): box(obstacle, Vector3((b - 1) * 0.8, 0.38 + y * 0.73, 0), Vector3(0.75, 0.68, 0.65), Color("fb9675") if y % 2 else Color("ee795e"))
		blocks.append({"node": obstacle, "lane": lane, "hit": false})
	rows.append({"node": root, "distance": row.distance, "safe": row.safe, "kind": row.kind, "blocks": blocks, "passed": false})

func _process(delta: float) -> void:
	var dt = minf(delta, 0.05)
	world_time += dt
	if hit_stop > 0 and phase in ["run", "boss"]:
		hit_stop -= dt
		dt *= 0.15
	update_particles(dt)
	shake = maxf(0, shake - dt * 2)
	if phase != "home": camera.position.x = lerpf(camera.position.x, sin(world_time * 53) * shake * 0.15 + avatar.position.x * 0.07, dt * 9)
	if phase == "run" or phase == "boss":
		elapsed += dt
		combo_timer = maxf(0, combo_timer - dt)
		if combo_timer <= 0: combo = 0
		stage_flash = maxf(0, stage_flash - dt)
		invulnerable = maxf(0, invulnerable - dt)
		strike_cooldown = maxf(0, strike_cooldown - dt)
		var axis = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		target_x = clampf(target_x + axis * dt * 9, -3.35, 3.35)
		if automation: auto_steer()
		avatar.position.x = move_toward(avatar.position.x, target_x, dt * 15)
		body.rotation.y = lerpf(body.rotation.y, -(target_x - avatar.position.x) * 0.1, dt * 10)
		body.rotation.z = lerpf(body.rotation.z, (avatar.position.x - target_x) * 0.14, dt * 10)
		left_leg.rotation.x = sin(elapsed * 18) * 0.7
		right_leg.rotation.x = -sin(elapsed * 18) * 0.7
		body.get_child(5).rotation.x = -sin(elapsed * 18) * 0.65
		body.get_child(6).rotation.x = sin(elapsed * 18) * 0.65
		body.position.y = absf(sin(elapsed * 18)) * 0.09
		avatar.visible = invulnerable <= 0 or int(invulnerable * 12) % 2 == 0
		power_left = maxf(0, power_left - dt)
		if power_left <= 0 and power_id >= 0: clear_power()
		var desired = 0.46 if small else 1.0 + float(profile.data.upgrades[0]) * 0.025
		if power_id >= 0 and family() == "size": desired = float(Catalog.POWERS[power_id][3])
		avatar.scale = avatar.scale.lerp(Vector3.ONE * desired, dt * 6)
		avatar.position.y = lerpf(avatar.position.y, 2.2 if family() == "flight" else 0.0, dt * 6)
		camera.fov = lerpf(camera.fov, 57.0 if power_id >= 0 else 49.0, dt * 3)
		if power_id in [2, 14, 16] and int(elapsed * 18) % 3 == 0: burst(avatar.position + Vector3(0, 0.2, 0.9), Color("ffd575"), 1)
		if phase == "run": update_run(dt)
		elif phase == "boss": update_boss(dt)
	if phase == "run" and stage_flash <= 0: banner.text = ""
	bar.value = distance / float(spec.length) * 100 if spec else 0
	power_label.text = ""
	ui.update(delta)
	if is_instance_valid(music): music.volume_db = -25 if profile.data.sound else -80
	if screen_at >= 0 and (elapsed >= screen_at or (phase in ["home", "shop", "map"] and world_time >= screen_at)):
		screen_at = -1
		capture.call_deferred()

func update_run(dt: float) -> void:
	var speed = 8.2 + float(profile.data.upgrades[1]) * 0.12
	if family() == "speed": speed *= 1.5
	distance += dt * speed
	art.move_environment(dt * speed)
	for tile in scenery: tile.position.z = fposmod(tile.position.z + dt * speed + 205, 210) - 205
	for row in rows:
		row.node.position.z = distance - float(row.distance)
		row.node.visible = row.node.position.z > -110 and row.node.position.z < 12
		if row.passed: continue
		for b in row.blocks:
			if b.hit: continue
			if row.kind == "moving":
				b.node.position.z = 0 if family() == "time" else sin(elapsed * 2) * 1.1
			if row.kind == "crusher":
				b.node.position.y = 2.5 if family() == "time" else absf(sin(elapsed * 1.6)) * 2.8
			if row.kind == "ball": b.node.get_child(0).rotation.x = elapsed * 2.5
			if row.kind == "fire":
				for j in range(1, b.node.get_child_count()): b.node.get_child(j).scale.y = 0.8 + sin(elapsed * 8 + j) * 0.22
			if row.kind == "spinner" and family() != "time": b.node.get_child(0).rotation.y = elapsed * 2
			var dx = absf(avatar.position.x - b.node.position.x)
			var ahead = float(row.distance) - distance - b.node.position.z
			var hit_width = 0.95 if small else 1.28
			if family() == "size": hit_width = avatar.scale.x * 0.75 + 0.9
			if family() == "clone": hit_width = 4.5
			if family() == "vehicle": hit_width = 1.7
			if (family() == "beam" or power_id == 16) and ahead < 13 and ahead > -1 and (dx < 1.6 or power_id == 19):
				destroy_block(b)
			elif ahead < 0.65 and ahead > -0.65 and dx < hit_width:
				if family() in ["size", "vehicle", "clone", "shield", "speed"]:
					destroy_block(b)
				elif family() == "flight" or (row.kind == "crusher" and b.node.position.y > (0.9 if small else 2.0)) or (family() == "time" and row.kind in ["laser", "spinner", "moving", "crusher"]) or (small and row.kind in ["hole", "gate", "laser"]):
					pass
				else:
					b.hit = true
					damage()
		if distance > float(row.distance) + 2: row.passed = true
	for c in coins:
		if c.taken: continue
		c.node.rotation.y += dt * 3
		if absf(distance - float(c.distance)) < 0.9 and (absf(avatar.position.x - float(c.x)) < 1.2 or family() == "magnet"):
			c.taken = true
			c.node.hide()
			run_coins += 2
			collected += 1
			add_combo()
			tone(760 + run_coins % 6 * 70, 0.035)
	for child in world.get_children():
		if child.has_meta("distance"): child.position.z = distance - float(child.get_meta("distance"))
	if is_instance_valid(showcase_orb) and not showcase_taken:
		showcase_orb.rotation.y += dt * 2
		showcase_orb.position.y = 1.2 + sin(elapsed * 3) * 0.15
		if distance >= float(spec.showcase_distance):
			showcase_taken = true
			showcase_orb.hide()
			if not automation or auto_powers:
				activate_power(int(spec.showcase))
				banner.text = "무료 파워!"
				stage_flash = 2
	if phase != "run": return
	if next_deal < spec.deals.size() and distance >= float(spec.deals[next_deal]):
		current_deal = Catalog.WORLDS[spec.biome].powers[(level + next_deal) % 3]
		next_deal += 1
		show_deal()
	elif distance >= float(spec.length):
		if spec.boss: start_boss()
		else: finish(true)

func family() -> String:
	return str(Catalog.POWERS[power_id][2]) if power_id >= 0 else ""

func damage() -> void:
	if invulnerable > 0 or phase not in ["run", "boss"]: return
	hp = maxi(0, hp - 1)
	hit_count += 1
	combo = 0
	hit_stop = 0.09
	invulnerable = 1.5
	shake = 0.8
	tone(90, 0.15)
	if profile.data.haptics: Input.vibrate_handheld(60)
	caption.text = "괜찮아요! 빈 길을 따라가요"
	if hp <= 0: finish(false)

func destroy_block(b: Dictionary) -> void:
	if b.hit: return
	b.hit = true
	# Throw the actual bricks and little guards, retaining each obstacle's colors.
	for original in b.node.get_children():
		if particles.size() >= 150: break
		if not original is Node3D: continue
		var piece = original.duplicate()
		add_child(piece)
		piece.global_transform = original.global_transform
		particles.append({"node": piece, "v": Vector3(randf_range(-6, 6), randf_range(5, 10), randf_range(-8, 2)), "life": randf_range(0.8, 1.4)})
	burst(b.node.global_position + Vector3(0, 1, 0), Color("fff0a3"), 4)
	b.node.hide()
	destroyed += 1
	add_combo()
	hit_stop = 0.035
	run_coins += 3
	shake = 0.4
	tone(135, 0.07)

func burst(pos: Vector3, color: Color, amount: int) -> void:
	for i in range(amount):
		if particles.size() >= 180: break
		var shard = box(self, pos, Vector3.ONE * randf_range(0.12, 0.4), color)
		particles.append({"node": shard, "v": Vector3(randf_range(-5, 5), randf_range(3, 9), randf_range(-6, 5)), "life": randf_range(0.5, 1.2)})

func update_particles(dt: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p = particles[i]
		p.life -= dt
		p.v.y -= dt * 18
		p.node.position += p.v * dt
		p.node.rotate_x(dt * 5)
		p.node.rotate_z(dt * 3)
		if p.life <= 0:
			p.node.queue_free()
			particles.remove_at(i)

func show_deal() -> void:
	phase = "deal"
	drag = false
	track("deal_shown", {"deal_type": Catalog.POWERS[current_deal][0]})
	if automation:
		skip_deal()
		if auto_powers: activate_power(current_deal)
		return
	ui.deal()

func skip_deal() -> void:
	track("deal_skipped", {"deal_type": Catalog.POWERS[current_deal][0]})
	clear_modal()
	phase = "boss" if is_instance_valid(boss) else "run"

func preview_reward() -> void:
	if phase != "deal": return
	track("deal_selected", {"deal_type": Catalog.POWERS[current_deal][0]})
	var ticket = rewards.begin()
	if ticket.is_empty():
		skip_deal()
		return
	phase = "preview"
	var p = card("파워 충전 중!", "무료 능력 체험입니다.\n실제 광고 시청으로 기록되지 않아요.")
	var countdown = label_at(p, "3", Vector2(24, 198), Vector2(392, 68), 48, LIME)
	countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button_at(p, "취소하고 계속 달리기", Vector2(24, 335), Vector2(392, 58), func():
		rewards.complete_preview(ticket, false)
		clear_modal()
		phase = "boss" if is_instance_valid(boss) else "run"
	)
	for i in range(3, 0, -1):
		if phase != "preview" or rewards.pending != ticket: return
		countdown.text = str(i)
		await get_tree().create_timer(1).timeout
	if phase != "preview": return
	if rewards.complete_preview(ticket, true):
		track("preview_complete", {"deal_type": Catalog.POWERS[current_deal][0]})
		clear_modal()
		phase = "boss" if is_instance_valid(boss) else "run"
		activate_power(current_deal)

func activate_power(id: int) -> void:
	clear_power()
	power_id = id
	power_left = 8
	small = false
	shake = 0.65
	hit_stop = 0.12
	tone(380, 0.25)
	burst(avatar.position + Vector3.UP, LIME, 32)
	caption.text = Catalog.POWER_DESC[id]
	banner.text = Catalog.POWER_NAMES[id] + "!"
	stage_flash = 1.8
	art.power_model(attachments, id)
	if family() == "clone":
		# Instance each mesh part rather than creating hundreds of character nodes.
		var template = art.character(attachments, Color("77cfa7"))
		for part in template.get_children():
			if not part is MeshInstance3D: continue
			var copies = MultiMeshInstance3D.new()
			var multi = MultiMesh.new()
			multi.transform_format = MultiMesh.TRANSFORM_3D
			multi.mesh = part.mesh
			multi.instance_count = int(Catalog.POWERS[id][3])
			copies.multimesh = multi
			copies.material_override = part.material_override
			attachments.add_child(copies)
			for i in range(multi.instance_count):
				var formation = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.48), Vector3((i % 5 - 2) * 0.9, 0, 1 + int(i / 5) * 0.55))
				multi.set_instance_transform(i, formation * part.transform)
		attachments.remove_child(template)
		template.queue_free()

func clear_power() -> void:
	power_id = -1
	power_left = 0
	if is_instance_valid(power_label): power_label.text = ""
	if is_instance_valid(attachments):
		for child in attachments.get_children(): child.queue_free()

func start_boss() -> void:
	phase = "boss"
	clear_power()
	for child in world.get_children():
		if child.has_meta("distance"): child.hide()
	boss = art.character(world, Color("b484d4"), [6, 2, 4, 9, 11, 2][mini(5, int(level / 5) - 1)])
	boss.position = Vector3(0, 0, -11)
	boss.scale = Vector3.ONE * 3.1
	boss.rotation.y = PI
	boss_warning = box(world, Vector3(0, 0.04, -1), Vector3(2.6, 0.05, 9), CORAL)
	boss_warning2 = box(world, Vector3(0, 0.045, -1), Vector3(2.6, 0.05, 9), CORAL)
	boss_warning2.hide()
	var boss_type = mini(5, int(level / 5) - 1)
	match boss_type:
		0: box(boss, Vector3(-0.55, 1.0, -0.25), Vector3(0.55, 0.95, 0.16), LIME)
		1: box(boss, Vector3(0, 2.25, 0), Vector3(0.85, 0.16, 0.75), CORAL)
		2:
			box(boss, Vector3(0, 0.4, 0), Vector3(1.8, 0.7, 1.8), Color("778765"))
			box(boss, Vector3(0, 1.05, -0.7), Vector3(0.2, 0.2, 1.5), INK)
		3:
			for side in [-1, 1]: box(boss, Vector3(side * 0.35, 2.24, 0), Vector3(0.17, 0.7, 0.17), CORAL)
		4:
			for j in range(5): box(boss, Vector3((j - 2) * 0.17, 2.24, 0), Vector3(0.12, 0.35 + (j % 2) * 0.15, 0.5), LIME)
		5:
			for side in [-1, 1]: box(boss, Vector3(side * 0.6, 1.6, 0), Vector3(0.55, 0.65, 0.8), CORAL)
	boss_hp = 8 + minf(level / 5.0, 3) * 2
	boss_bar.max_value = boss_hp
	boss_bar.value = boss_hp
	boss_bar.show()
	boss_clock = 0
	boss_lane = 1
	boss_hit = false
	banner.text = Catalog.BOSSES[mini(5, level / 5 - 1)]
	caption.text = "빨간 길을 피하고 펀치!"
	current_deal = 18
	show_deal()

func update_boss(dt: float) -> void:
	boss_clock += dt
	var cycle = 2.0 - mini(5, int(level / 5) - 1) * 0.05
	var strike_time = cycle * 0.62
	var telegraph = boss_clock < strike_time
	boss_warning.position.x = (int(boss_danger[0]) - 1) * 2.8
	boss_warning.visible = telegraph
	boss_warning.scale.z = 0.2 + minf(1, boss_clock / strike_time) * 0.8
	boss_warning2.visible = telegraph and boss_danger.size() > 1
	if boss_danger.size() > 1:
		boss_warning2.position.x = (int(boss_danger[1]) - 1) * 2.8
		boss_warning2.scale.z = boss_warning.scale.z
	boss.position.y = maxf(0, sin(boss_clock / cycle * PI)) * 0.35
	boss.get_child(5).rotation.x = -boss_clock / cycle * 1.2 if telegraph else 0.9
	boss.get_child(6).rotation.x = boss.get_child(5).rotation.x
	if boss_clock > cycle:
		boss_clock = 0
		boss_hit = false
		boss_turn += 1
		var type = mini(5, int(level / 5) - 1)
		match type:
			0: boss_danger = [boss_turn % 3]
			1: boss_danger = [0, 2] if boss_turn % 2 else [1]
			2: boss_danger = [clampi(roundi(avatar.position.x / 2.8) + 1, 0, 2)]
			3: boss_danger = [0, 1] if boss_turn % 2 else [1, 2]
			4:
				var safe = boss_turn % 3
				boss_danger = []
				for lane in range(3):
					if lane != safe: boss_danger.append(lane)
			5: boss_danger = [0, 2] if boss_turn % 3 == 0 else ([0, 1] if boss_turn % 3 == 1 else [1, 2])
		boss_lane = int(boss_danger[0])
		caption.text = "빨간 길을 피해요!"
	if boss_clock > strike_time and not boss_hit:
		boss_hit = true
		for lane in boss_danger:
			burst(Vector3((int(lane) - 1) * 2.8, 0.15, 0), CORAL, 12)
			if absf(avatar.position.x - (int(lane) - 1) * 2.8) < 1.3 and family() not in ["shield", "flight", "size"]: damage()
		caption.text = "지금! 펀치 기회!"
	boss.rotation.z = sin(boss_clock * PI / cycle) * 0.07
	boss_bar.value = boss_hp
	if automation: strike()

func strike() -> void:
	if phase != "boss" or strike_cooldown > 0: return
	strike_cooldown = 0.38
	boss_hp -= (1.0 + float(profile.data.upgrades[2]) * 0.15) * (3.0 if power_id >= 0 else (1.5 if boss_hit else 1.0))
	burst(boss.position + Vector3(0, 2, 1), LIME, 7)
	shake = 0.35
	tone(160, 0.07)
	if boss_hp <= 0:
		burst(boss.position + Vector3(0, 3, 0), CORAL, 40)
		boss.hide()
		finish(true)

func toggle_small() -> void:
	if phase == "boss":
		strike()
	elif phase == "run" and power_id < 0:
		small = not small
		tone(490 if small else 290, 0.08)
		caption.text = "낮은 문도 쏙!" if small else "다시 씩씩하게!"

func finish(won: bool) -> void:
	if finished: return
	finished = true
	phase = "result"
	avatar.visible = true
	clear_power()
	var mission_bonus = 30 if won and mission_complete() else 0
	var payout = run_coins + (75 if won else 0) + mission_bonus
	var stars = 0
	if won:
		stars = 1 + (1 if hit_count == 0 else 0) + (1 if collected >= total_coins * 0.65 else 0)
		if not profile.data.has("stars"): profile.data.stars = {}
		profile.data.stars[str(level)] = maxi(stars, int(profile.data.stars.get(str(level), 0)))
	profile.data.coins = mini(10000000, int(profile.data.coins) + payout)
	if won:
		profile.data.wins += 1
		if int(profile.data.wins) % 2 == 0 and int(profile.data.wins) <= 22:
			track("skin_unlock", {"skin": Catalog.SKINS[int(profile.data.wins) / 2]})
		profile.data.level = maxi(int(profile.data.level), level + 1)
		burst(avatar.position + Vector3.UP * 3, LIME, 70)
	profile.save()
	track("level_complete" if won else "level_fail", {"coins": payout, "duration": elapsed, "stars": stars})
	if automation:
		print("AUTOPLAY_RESULT ", JSON.stringify({"level": level, "won": won, "hp": hp, "duration": elapsed, "powers": auto_powers}))
		get_tree().quit(0 if won else 1)
		return
	ui.result(won, payout, stars, mission_bonus)

func pause_game() -> void:
	if phase not in ["run", "boss"]: return
	var previous = phase
	phase = "pause"
	drag = false
	var p = card("잠깐 쉬어가기", "달리기는 여기서 기다리고 있어요.")
	button_at(p, "계속 달리기", Vector2(24, 190), Vector2(392, 60), func():
		clear_modal()
		phase = previous
	, true)
	button_at(p, "소리: " + ("ON" if profile.data.sound else "OFF"), Vector2(24, 269), Vector2(190, 58), func():
		profile.data.sound = not profile.data.sound
		profile.save()
		phase = previous
		pause_game()
	)
	button_at(p, "진동: " + ("ON" if profile.data.haptics else "OFF"), Vector2(226, 269), Vector2(190, 58), func():
		profile.data.haptics = not profile.data.haptics
		profile.save()
		phase = previous
		pause_game()
	)
	button_at(p, "저장 데이터 안내", Vector2(24, 347), Vector2(392, 54), func(): show_privacy(previous))

func show_privacy(previous: String) -> void:
	var p = card("내 데이터", "이 버전은 오프라인으로 동작합니다. 진행 기록과 진단 이벤트는 기기에만 저장돼요.")
	button_at(p, "계속 달리기", Vector2(24, 228), Vector2(392, 58), func():
		clear_modal()
		phase = previous
	, true)
	button_at(p, "진행 기록 지우기...", Vector2(24, 321), Vector2(392, 58), func():
		var confirmation = card("모든 기록을 지울까요?", "진행 기록과 진단 이벤트가 삭제됩니다. 되돌릴 수 없어요.")
		button_at(confirmation, "취소", Vector2(24, 222), Vector2(392, 58), func(): show_privacy(previous), true)
		button_at(confirmation, "정말 삭제하기", Vector2(24, 318), Vector2(392, 58), func():
			profile = Profile.new()
			profile.save()
			DirAccess.remove_absolute("user://preview_events.jsonl")
			level = 1
			start_level()
		)
	)

func show_shop() -> void:
	if phase in ["deal", "preview"]: return
	ui.show_shop(phase, false)

func render_shop(previous: String) -> void:
	ui.show_shop(previous, false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE: pause_game()
		if event.keycode == KEY_SPACE: toggle_small()
	if phase not in ["run", "boss"]: return
	if event is InputEventScreenTouch:
		drag = event.pressed
		drag_x = event.position.x
		drag_start = target_x
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		drag = event.pressed
		drag_x = event.position.x
		drag_start = target_x
	elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and drag:
		target_x = clampf(drag_start + (event.position.x - drag_x) / 47, -3.35, 3.35)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(modal):
		if phase == "preview":
			rewards.cancel()
			clear_modal()
			phase = "boss" if is_instance_valid(boss) else "run"
		pause_game()
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		track("session_end", {"duration_ms": Time.get_ticks_msec() - session_started})

func tone(hz: float, duration: float) -> void:
	if DisplayServer.get_name() == "headless": return
	if not profile.data.sound or not is_instance_valid(audio_player): return
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples = int(duration * 22050)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var envelope = pow(1.0 - float(i) / samples, 2)
		bytes.encode_s16(i * 2, int(sin(float(i) / 22050 * hz * TAU) * envelope * 6500))
	stream.data = bytes
	audio_player.stream = stream
	audio_player.play()

func track(event: String, extra: Dictionary = {}) -> void:
	var path = "user://preview_events.jsonl"
	if FileAccess.file_exists(path) and FileAccess.get_file_as_bytes(path).size() > 512000:
		DirAccess.remove_absolute(path)
	var f = FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if f == null: return
	f.seek_end()
	var payload = {"event": event, "level": level, "mode": "preview", "time": Time.get_unix_time_from_system(), "player_state": phase}
	payload.merge(extra)
	f.store_line(JSON.stringify(payload))

func auto_steer() -> void:
	if phase == "boss":
		for lane in range(3):
			if lane not in boss_danger:
				target_x = (lane - 1) * 2.8
				return
		return
	for row in rows:
		if float(row.distance) > distance - 1:
			target_x = (int(row.safe) - 1) * 2.8
			return

func capture() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://capture-" + capture_mode + ".png")
	print("SCREENSHOT_SAVED ", capture_mode)

func add_combo() -> void:
	combo += 1
	combo_timer = 2.0

func mission_text() -> String:
	match int(spec.mission):
		0: return "이번 목표  ·  코인 %d / 24" % mini(collected, 24)
		1: return "이번 목표  ·  한 번도 부딪히지 않기" + ("  실패" if hit_count > 0 else "")
		_: return "이번 목표  ·  장애물 파괴 %d / 6" % mini(destroyed, 6)

func mission_complete() -> bool:
	match int(spec.mission):
		0: return collected >= 24
		1: return hit_count == 0
		_: return destroyed >= 6

func build_music() -> void:
	# A lightweight original marimba loop. No third-party audio assets.
	music = AudioStreamPlayer.new()
	add_child(music)
	if DisplayServer.get_name() == "headless": return
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	var seconds = 8.0
	var count = int(seconds * 22050)
	stream.loop_end = count
	var bytes = PackedByteArray()
	bytes.resize(count * 2)
	var melody = [523.25, 0, 659.25, 783.99, 0, 659.25, 587.33, 0, 523.25, 659.25, 0, 880.0, 783.99, 0, 659.25, 587.33]
	for i in range(count):
		var t = float(i) / 22050
		var step = int(t / 0.5) % 16
		var local = fmod(t, 0.5)
		var frequency = melody[step]
		var note = (sin(t * frequency * TAU) + 0.22 * sin(t * frequency * 2 * TAU)) * exp(-local * 12) if frequency > 0 else 0.0
		var bass_freq = 130.81 if step < 8 else 174.61
		var bass = sin(t * bass_freq * TAU) * exp(-fmod(t, 1.0) * 7) * 0.35
		bytes.encode_s16(i * 2, int((note + bass) * 9000))
	stream.data = bytes
	music.stream = stream
	music.volume_db = -25
	music.play()

func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	if is_instance_valid(audio_player):
		audio_player.stop()
		audio_player.stream = null
