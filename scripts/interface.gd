extends RefCounted
const Icon = preload("res://scripts/ui_icon.gd")
const FONT = preload("res://assets/Jua-Regular.ttf")
const INK = Color("29415a")
const MUTED = Color("8393a1")
const WHITE = Color("fffdf7")
const GREEN = Color("43c797")
const ORANGE = Color("ff9866")
var g
var hearts: Array = []
var stage_label: Label
var coin_label: Label
var goal_label: Label
var combo_label: Label
var hud_bottom: Control
var ui_clock = 0.0
var home_title: Control
var result_won = false

func _init(game): g = game

func style(color: Color, radius: int = 22, shadow: bool = false) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	if shadow:
		s.shadow_color = Color(0.13, 0.26, 0.32, 0.16)
		s.shadow_size = 0
		s.shadow_offset = Vector2(0, 5)
	return s

func panel(parent: Control, pos: Vector2, size: Vector2, color: Color = WHITE, radius: int = 22) -> Panel:
	var p = Panel.new()
	p.position = pos
	p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", style(color, radius, true))
	parent.add_child(p)
	return p

func text(parent: Control, value: String, pos: Vector2, size: Vector2, fs: int = 20, color: Color = INK, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label = Label.new()
	label.text = value
	label.position = pos
	label.size = size
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", fs)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func icon(parent: Control, type: String, pos: Vector2, size: Vector2, color: Color = Color("ffc54d")) -> Control:
	var n = Icon.new()
	n.kind = type
	n.color = color
	n.position = pos
	n.size = size
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(n)
	return n

func button(parent: Control, value: String, pos: Vector2, size: Vector2, action: Callable, primary: bool = true) -> Button:
	var b = Button.new()
	b.text = value
	b.position = pos
	b.size = size
	b.pivot_offset = size / 2
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 23 if primary else 18)
	var color = GREEN if primary else WHITE
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box_style = style(color.lightened(0.1) if state == "hover" else (Color("dae4e7") if state == "disabled" else color), 22, state != "pressed")
		if not primary:
			box_style.set_border_width_all(1)
			box_style.border_color = Color("e0e9e5")
		b.add_theme_stylebox_override(state, box_style)
		b.add_theme_color_override("font_" + ("color" if state == "normal" else state + "_color"), Color.WHITE if primary else INK)
	b.add_theme_color_override("font_disabled_color", Color("95a6ad"))
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func():
		g.tone(480, 0.04)
		action.call()
	)
	b.button_down.connect(func(): b.scale = Vector2.ONE * 0.96)
	b.button_up.connect(func():
		if is_instance_valid(b): b.scale = Vector2.ONE
	)
	parent.add_child(b)
	return b

func build() -> void:
	var layer = CanvasLayer.new()
	g.add_child(layer)
	g.hud = Control.new()
	g.hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	g.hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(g.hud)
	var top = panel(g.hud, Vector2(20, 24), Vector2(440, 96), Color(1, 0.99, 0.96, 0.97), 26)
	stage_label = text(top, "", Vector2(18, 8), Vector2(270, 28), 19)
	coin_label = text(top, "0", Vector2(323, 6), Vector2(72, 32), 21)
	icon(top, "coin", Vector2(289, 8), Vector2(29, 29))
	g.bar = ProgressBar.new()
	g.bar.show_percentage = false
	g.bar.position = Vector2(18, 49)
	g.bar.size = Vector2(251, 11)
	g.bar.add_theme_stylebox_override("background", style(Color("e3ece8"), 5))
	g.bar.add_theme_stylebox_override("fill", style(GREEN, 5))
	top.add_child(g.bar)
	for i in range(3): hearts.append(icon(top, "heart", Vector2(306 + i * 28, 44), Vector2(25, 25), Color("ff7c85")))
	goal_label = text(top, "", Vector2(18, 68), Vector2(380, 20), 13, MUTED)
	g.pause_button = button(g.hud, "", Vector2(402, 135), Vector2(58, 55), g.pause_game, false)
	icon(g.pause_button, "pause", Vector2(10, 7), Vector2(38, 38), INK)
	g.banner = text(g.hud, "", Vector2(20, 195), Vector2(440, 50), 34, INK, HORIZONTAL_ALIGNMENT_CENTER)
	g.banner.add_theme_color_override("font_outline_color", WHITE)
	g.banner.add_theme_constant_override("outline_size", 6)
	g.banner.add_theme_color_override("font_shadow_color", Color(0.16, 0.32, 0.4, 0.35))
	g.banner.add_theme_constant_override("shadow_offset_y", 3)
	g.power_label = text(g.hud, "", Vector2(34, 252), Vector2(412, 31), 21, INK, HORIZONTAL_ALIGNMENT_CENTER)
	combo_label = text(g.hud, "", Vector2(20, 310), Vector2(440, 40), 29, Color("f18b50"), HORIZONTAL_ALIGNMENT_CENTER)
	combo_label.add_theme_color_override("font_outline_color", WHITE)
	combo_label.add_theme_constant_override("outline_size", 5)
	hud_bottom = Control.new()
	hud_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.hud.add_child(hud_bottom)
	panel(hud_bottom, Vector2(44, 693), Vector2(392, 35), Color(1, 0.99, 0.96, 0.86), 17)
	g.caption = text(hud_bottom, "", Vector2(28, 691), Vector2(424, 36), 20, INK, HORIZONTAL_ALIGNMENT_CENTER)
	g.shrink_button = button(hud_bottom, "작아지기", Vector2(124, 749), Vector2(232, 65), g.toggle_small)
	text(hud_bottom, "좌우로 드래그해서 피하세요", Vector2(30, 826), Vector2(420, 21), 13, INK, HORIZONTAL_ALIGNMENT_CENTER)
	g.stats = Label.new()
	g.stats.hide()
	g.hud.add_child(g.stats)
	g.boss_bar = ProgressBar.new()
	g.boss_bar.position = Vector2(88, 291)
	g.boss_bar.size = Vector2(304, 12)
	g.boss_bar.show_percentage = false
	g.boss_bar.add_theme_stylebox_override("background", style(Color("e5b5bb"), 6))
	g.boss_bar.add_theme_stylebox_override("fill", style(Color("fa7380"), 6))
	g.boss_bar.size.y = 12
	g.hud.add_child(g.boss_bar)
	g.modal = Control.new()
	g.modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(g.modal)
	g.modal.hide()

func update(dt: float) -> void:
	ui_clock += dt
	g.hud.visible = g.phase in ["run", "boss", "deal", "preview", "pause", "result"]
	stage_label.text = "%s  ·  %02d" % [g.Catalog.WORLDS[g.spec.biome].name, g.level]
	coin_label.text = str(g.run_coins)
	for i in range(3):
		hearts[i].color = Color("ff7c85") if i < g.hp else Color("e2dce0")
		hearts[i].queue_redraw()
	goal_label.text = g.mission_text()
	combo_label.text = "%d COMBO!" % g.combo if g.combo >= 3 and g.combo_timer > 0 else ""
	combo_label.scale = Vector2.ONE * (1 + maxf(0, g.combo_timer - 1.7) * 0.15)
	if g.phase == "home":
		g.body.rotation.y = PI + sin(ui_clock * 0.7) * 0.3
		g.body.position.y = sin(ui_clock * 2) * 0.035
		g.body.get_child(5).rotation.x = sin(ui_clock * 2) * 0.15
	if g.phase == "run":
		g.shrink_button.text = "원래 크기로" if g.small else "작아지기"
		g.shrink_button.disabled = g.power_id >= 0
	elif g.phase == "boss":
		g.shrink_button.text = "펀치!" if g.strike_cooldown <= 0 else "다음 공격 준비"
		g.shrink_button.disabled = g.strike_cooldown > 0
	if g.power_id >= 0:
		g.power_label.text = "%s  %.1fs" % [g.Catalog.POWER_NAMES[g.power_id], g.power_left]

func show_home() -> void:
	g.clear_modal()
	g.phase = "home"
	g.modal.show()
	g.hud.hide()
	g.world.hide()
	g.avatar.position = Vector3.ZERO
	g.avatar.scale = Vector3.ONE * 1.5
	g.avatar.visible = true
	g.body.rotation.y = PI
	g.camera.position = Vector3(4.8, 4, 8.5)
	g.camera.look_at(Vector3(0, 1.6, 0))
	g.camera.fov = 43
	text(g.modal, "TAKE", Vector2(26, 32), Vector2(290, 54), 52, INK)
	text(g.modal, "THE DEAL", Vector2(26, 83), Vector2(425, 65), 60, Color.WHITE)
	text(g.modal, "평범하게 달릴까, 화끈하게 부술까?", Vector2(29, 155), Vector2(425, 34), 19, INK)
	var wallet = panel(g.modal, Vector2(335, 32), Vector2(123, 44))
	icon(wallet, "coin", Vector2(7, 7), Vector2(30, 30))
	text(wallet, str(g.profile.data.coins), Vector2(43, 4), Vector2(75, 37), 19)
	var tag = panel(g.modal, Vector2(136, 505), Vector2(208, 37), WHITE, 18)
	text(tag, g.Catalog.SKIN_NAMES[int(g.profile.data.skin)], Vector2(0, 0), tag.size, 17, INK, HORIZONTAL_ALIGNMENT_CENTER)
	var p = panel(g.modal, Vector2(24, 566), Vector2(432, 92), WHITE, 24)
	text(p, "다음 모험", Vector2(20, 12), Vector2(340, 22), 14, MUTED)
	text(p, "%s  /  STAGE %02d" % [g.Catalog.WORLDS[g.spec.biome].name, g.level], Vector2(20, 35), Vector2(345, 36), 23)
	icon(p, "arrow", Vector2(365, 28), Vector2(40, 40), GREEN)
	button(g.modal, "달리기 시작", Vector2(24, 681), Vector2(432, 66), g.start_level)
	button(g.modal, "스테이지", Vector2(24, 766), Vector2(136, 53), show_map, false)
	button(g.modal, "꾸미기", Vector2(172, 766), Vector2(136, 53), func(): show_shop("home", false), false)
	button(g.modal, "업그레이드", Vector2(320, 766), Vector2(136, 53), func(): show_shop("home", true), false)
	text(g.modal, "강제 광고 없이 · 모든 스테이지 무료 플레이", Vector2(24, 827), Vector2(432, 22), 12, INK, HORIZONTAL_ALIGNMENT_CENTER)

func sheet(title: String, subtitle: String, y: float = 354, height: float = 470) -> Panel:
	g.clear_modal()
	g.modal.show()
	var shade = ColorRect.new()
	shade.color = Color(0.12, 0.22, 0.3, 0.4)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	g.modal.add_child(shade)
	var p = panel(g.modal, Vector2(16, y), Vector2(448, height), WHITE, 30)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	text(p, title, Vector2(24, 26), Vector2(400, 52), 33, INK, HORIZONTAL_ALIGNMENT_CENTER)
	var subtitle_label = text(p, subtitle, Vector2(24, 84), Vector2(400, 48), 17, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.pivot_offset = Vector2(224, height)
	p.scale = Vector2(0.97, 0.97)
	p.create_tween().tween_property(p, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return p

func deal() -> void:
	var id = g.current_deal
	var p = sheet("이번엔 크게 놀아볼까?", "안 받아도 통과할 수 있어요", 331, 490)
	var tile = panel(p, Vector2(24, 151), Vector2(400, 112), Color("eef6eb"), 22)
	var preview = SubViewport.new()
	preview.size = Vector2i(180, 170)
	preview.transparent_bg = true
	preview.own_world_3d = true
	preview.render_target_update_mode = SubViewport.UPDATE_ONCE
	tile.add_child(preview)
	var preview_root = viewport_root(preview)
	var preview_model = g.art.character(preview_root, Color("ff8a58"))
	preview_model.rotation.y = PI - 0.4
	g.art.power_model(preview_model, id)
	var preview_camera = preview_root.get_child(2)
	preview_camera.position = Vector3(0, 2.2, 6.8)
	preview_camera.look_at(Vector3(0, 1.0, 0))
	preview_camera.fov = 40
	if id in [0, 1, 13, 18]: preview_model.scale = Vector3.ONE * 1.25
	var thumbnail = TextureRect.new()
	thumbnail.texture = preview.get_texture()
	thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumbnail.position = Vector2(4, 2)
	thumbnail.size = Vector2(119, 108)
	thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(thumbnail)
	text(tile, g.Catalog.POWER_NAMES[id], Vector2(130, 18), Vector2(264, 38), 28)
	var description = text(tile, g.Catalog.POWER_DESC[id], Vector2(130, 60), Vector2(259, 42), 15, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(p, "%s 받기" % g.Catalog.POWER_NAMES[id], Vector2(24, 283), Vector2(400, 66), g.preview_reward)
	text(p, "무료 능력 체험 · 이 버전에는 실제 광고가 없어요", Vector2(24, 357), Vector2(400, 22), 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	button(p, "괜찮아, 그냥 달릴게", Vector2(24, 401), Vector2(400, 58), g.skip_deal, false)

func result(won: bool, payout: int, stars: int, mission_bonus: int) -> void:
	result_won = won
	var p = sheet("멋지게 해냈어요!" if won else "다시 해볼까요?", "%s  ·  STAGE %02d" % [g.Catalog.WORLDS[g.spec.biome].name, g.level], 297, 528)
	for i in range(3):
		var s = icon(p, "star", Vector2(108 + i * 77, 139 if i != 1 else 125), Vector2(67, 67), Color("ffc85b") if i < stars else Color("dce6e7"))
		s.pivot_offset = s.size / 2
		s.scale = Vector2.ZERO
		s.create_tween().tween_property(s, "scale", Vector2.ONE, 0.25).set_delay(i * 0.13).set_trans(Tween.TRANS_BACK)
	var coin = panel(p, Vector2(24, 223), Vector2(400, 69), Color("fff0cf"), 20)
	icon(coin, "coin", Vector2(25, 16), Vector2(39, 39))
	text(coin, "+%d" % payout, Vector2(74, 6), Vector2(151, 57), 33)
	text(coin, "목표 보너스 +%d" % mission_bonus if mission_bonus > 0 else "획득한 코인", Vector2(215, 14), Vector2(172, 42), 15, Color("a17c41"))
	text(p, "무피격 + 코인 수집으로 별 3개에 도전!" if won else "모은 코인은 그대로 보관했어요", Vector2(24, 305), Vector2(400, 27), 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	button(p, "다음 스테이지" if won else "다시 달리기", Vector2(24, 355), Vector2(400, 67), func():
		if won: g.level += 1
		g.start_level()
	)
	button(p, "홈으로", Vector2(24, 441), Vector2(191, 55), func():
		g.level = int(g.profile.data.level)
		g.start_level()
		show_home()
	, false)
	button(p, "업그레이드", Vector2(233, 441), Vector2(191, 55), func(): show_shop("result", true), false)

func show_map() -> void:
	g.clear_modal()
	g.phase = "map"
	g.modal.show()
	panel(g.modal, Vector2.ZERO, Vector2(480, 854), Color("f0f8f5"), 0)
	text(g.modal, "작은 달리기, 큰 모험", Vector2(24, 26), Vector2(430, 52), 30)
	text(g.modal, "6개의 월드 · 30개의 도전", Vector2(24, 85), Vector2(432, 27), 17, MUTED)
	for zone in range(6):
		var p = panel(g.modal, Vector2(24, 138 + zone * 96), Vector2(432, 83), WHITE, 20)
		text(p, "%02d  %s" % [zone + 1, g.Catalog.WORLDS[zone].name], Vector2(16, 7), Vector2(395, 25), 17)
		for j in range(5):
			var stage = zone * 5 + j + 1
			var unlocked = stage <= int(g.profile.data.level)
			var b = button(p, str(stage) if unlocked else "-", Vector2(16 + j * 82, 38), Vector2(70, 32), func():
				g.level = stage
				g.start_level()
			, false)
			b.add_theme_font_size_override("font_size", 15)
			b.add_theme_stylebox_override("normal", style(Color("e3f3ec") if unlocked else Color("edf0f1"), 12))
			b.disabled = not unlocked
			var best = int(g.profile.data.get("stars", {}).get(str(stage), 0))
			if best > 0: icon(b, "star", Vector2(47, 7), Vector2(17, 17))
	button(g.modal, "돌아가기", Vector2(24, 763), Vector2(432, 59), show_home)

func show_shop(previous: String, upgrades: bool = false) -> void:
	g.phase = "shop"
	g.clear_modal()
	g.modal.show()
	panel(g.modal, Vector2.ZERO, Vector2(480, 854), Color("eff7f4"), 0)
	text(g.modal, "조금 더 강하게" if upgrades else "오늘은 어떤 모습?", Vector2(24, 27), Vector2(432, 48), 32)
	icon(g.modal, "coin", Vector2(26, 88), Vector2(28, 28))
	text(g.modal, str(g.profile.data.coins), Vector2(64, 86), Vector2(300, 33), 22)
	button(g.modal, "꾸미기", Vector2(24, 138), Vector2(207, 48), func(): show_shop(previous, false), not upgrades)
	button(g.modal, "업그레이드", Vector2(249, 138), Vector2(207, 48), func(): show_shop(previous, true), upgrades)
	if upgrades:
		for i in range(3):
			var rank = int(g.profile.data.upgrades[i])
			var cost = g.Catalog.PRICES[rank] if rank < 6 else 0
			var p = panel(g.modal, Vector2(24, 214 + i * 156), Vector2(432, 137))
			text(p, ["더 크게", "더 빠르게", "더 강하게"][i], Vector2(20, 15), Vector2(230, 32), 25)
			text(p, ["기본 크기 증가", "달리기 속도 증가", "보스 펀치 강화"][i], Vector2(20, 55), Vector2(220, 26), 15, MUTED)
			for tick in range(6): panel(p, Vector2(20 + tick * 31, 97), Vector2(23, 8), GREEN if tick < rank else Color("dbe6e5"), 4)
			var b = button(p, str(cost) + " 코인" if rank < 6 else "최고 레벨", Vector2(256, 51), Vector2(158, 58), func():
				if g.profile.data.upgrades[i] >= 6 or g.profile.data.coins < cost: return
				g.profile.data.coins -= cost
				g.profile.data.upgrades[i] += 1
				g.profile.save()
				g.track("upgrade", {"type": i})
				show_shop(previous, true)
			)
			b.add_theme_font_size_override("font_size", 18)
			b.disabled = rank >= 6 or g.profile.data.coins < cost
	else:
		for i in range(12):
			var unlocked = int(g.profile.data.wins) >= i * 2
			var selected = int(g.profile.data.skin) == i
			var p = panel(g.modal, Vector2(24 + i % 3 * 148, 212 + int(i / 3) * 124), Vector2(136, 110), Color("d7efe3") if selected else WHITE, 20)
			# Real 3D skin previews, sharing the game's mesh and accessory definitions.
			var viewport = SubViewport.new()
			viewport.size = Vector2i(128, 120)
			viewport.transparent_bg = true
			viewport.own_world_3d = true
			viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			p.add_child(viewport)
			var model = g.art.character(viewport_root(viewport), Color(g.Catalog.COLORS[i]), i)
			model.rotation.y = PI - 0.35
			var texture = TextureRect.new()
			texture.texture = viewport.get_texture()
			texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture.position = Vector2(28, 2)
			texture.size = Vector2(80, 72)
			texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
			p.add_child(texture)
			var b = button(p, g.Catalog.SKIN_NAMES[i] if unlocked else "%d승에 해제" % (i * 2), Vector2(7, 76), Vector2(122, 27), func():
				g.profile.data.skin = i
				g.profile.save()
				g.rebuild_avatar()
				show_shop(previous, false)
			, false)
			b.add_theme_font_size_override("font_size", 14)
			b.disabled = not unlocked
	button(g.modal, "돌아가기", Vector2(24, 758), Vector2(432, 61), func():
		if previous == "home": show_home()
		elif previous == "result":
			g.level = int(g.profile.data.level)
			g.start_level()
			show_home()
		else:
			g.clear_modal()
			g.phase = previous
	)

func viewport_root(viewport: SubViewport) -> Node3D:
	var root = Node3D.new()
	viewport.add_child(root)
	var env = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.28
	root.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.light_energy = 0.55
	sun.rotation_degrees = Vector3(-30, -20, 0)
	root.add_child(sun)
	var cam = Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(0, 1.4, 4.4)
	cam.look_at(Vector3(0, 1.2, 0))
	cam.fov = 35
	return root
