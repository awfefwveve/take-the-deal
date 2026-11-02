extends RefCounted

var g
var decor: Node3D
var road: MeshInstance3D
var sea: MeshInstance3D
var edge: Array = []
var props: Array = []
var env: Environment
var biome = 0
const PALETTES = [
	["86dee9", "35bfcb", "fff2cf", "ff8e69", "34b985", "fff8e9"],
	["ffce9e", "e9986e", "ffe8c8", "f27053", "cc784d", "ffecbb"],
	["d9c5fa", "ae8bdd", "fff0f7", "ed76a5", "8f78d5", "fff6fc"],
	["b6e7f3", "68b9d5", "f1fcff", "709cec", "5199bd", "d6f8ff"],
	["95d8c9", "409f99", "dcead8", "eea951", "3f7376", "d3f7de"],
	["4f548f", "343660", "7d83b6", "ee7da6", "626798", "afbdf6"]
]

func _init(game): g = game

func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, top: float = -1.0) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top < 0 else top
	mesh.height = height
	mesh.radial_segments = 16
	n.mesh = mesh
	n.material_override = g.material(color)
	parent.add_child(n)
	n.position = pos
	return n

func capsule(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	var mesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2)
	mesh.radial_segments = 16
	mesh.rings = 8
	n.mesh = mesh
	n.material_override = g.material(color)
	parent.add_child(n)
	n.position = pos
	return n

func ring(parent: Node3D, pos: Vector3, radius: float, thickness: float, color: Color) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	var mesh = TorusMesh.new()
	mesh.inner_radius = radius - thickness
	mesh.outer_radius = radius + thickness
	mesh.rings = 24
	mesh.ring_segments = 8
	n.mesh = mesh
	n.material_override = g.material(color)
	parent.add_child(n)
	n.position = pos
	return n

func character(parent: Node3D, color: Color, skin: int = -1) -> Node3D:
	var root = Node3D.new()
	parent.add_child(root)
	capsule(root, Vector3(0, 1.0, 0), 0.38, 1.05, color)
	g.sphere(root, Vector3(0, 1.83, 0), 0.46, color.lightened(0.1))
	var visor = capsule(root, Vector3(0, 1.84, -0.36), 0.18, 0.64, Color("253653"))
	visor.rotation.z = PI / 2
	g.sphere(root, Vector3(0.16, 1.87, -0.52), 0.065, Color.WHITE)
	g.sphere(root, Vector3(-0.16, 1.87, -0.52), 0.065, Color.WHITE)
	capsule(root, Vector3(-0.47, 1.05, 0), 0.135, 0.75, color)
	capsule(root, Vector3(0.47, 1.05, 0), 0.135, 0.75, color)
	capsule(root, Vector3(-0.21, 0.32, 0), 0.17, 0.64, color.darkened(0.09))
	capsule(root, Vector3(0.21, 0.32, 0), 0.17, 0.64, color.darkened(0.09))
	for side in [-1, 1]:
		var shoe = g.sphere(root, Vector3(side * 0.21, 0.12, -0.1), 0.2, Color("fcf9ee"))
		shoe.scale = Vector3(0.85, 0.65, 1.3)
	# A visible backpack and band keep the rear silhouette readable while running.
	var pack = capsule(root, Vector3(0, 1.09, 0.31), 0.22, 0.62, color.darkened(0.18))
	pack.scale.z = 0.7
	g.box(root, Vector3(0, 1.12, 0.475), Vector3(0.18, 0.08, 0.04), Color("fff1a8"))
	costume(root, skin, color)
	return root

func costume(root: Node3D, skin: int, color: Color) -> void:
	match skin:
		1:
			ring(root, Vector3(0, 1.96, 0), 0.42, 0.035, Color("ef5d72"))
			for side in [-1, 1]:
				var scarf = g.box(root, Vector3(side * 0.17, 1.65, 0.52), Vector3(0.16, 0.65, 0.055), Color("ef5d72"))
				scarf.rotation.z = side * 0.25
		2:
			cylinder(root, Vector3(0, 2.26, 0), 0.045, 0.28, Color("445674"))
			g.sphere(root, Vector3(0, 2.43, 0), 0.12, Color("ff705b"))
			for side in [-1, 1]: cylinder(root, Vector3(side * 0.47, 1.85, 0), 0.15, 0.18, Color("f9d569")).rotation.z = PI / 2
		3:
			g.box(root, Vector3(0.14, 2.2, 0), Vector3(0.12, 0.3, 0.3), Color("406655"))
			g.box(root, Vector3(-0.15, 1.78, -0.44), Vector3(0.1, 0.3, 0.04), Color("fce7ad")).rotation.z = 0.4
		4:
			cylinder(root, Vector3(0, 2.18, 0), 0.49, 0.13, Color("263c75"))
			cylinder(root, Vector3(0, 2.27, 0), 0.35, 0.18, Color("3f61a4"))
			g.sphere(root, Vector3(0, 2.23, -0.39), 0.09, Color("ffdc75"))
		5:
			g.sphere(root, Vector3(0, 1.76, -0.6), 0.12, Color("ff586b"))
			for side in [-1, 1]: g.sphere(root, Vector3(side * 0.42, 1.95, 0), 0.25, Color("faab67"))
			cylinder(root, Vector3(0, 2.3, 0), 0.28, 0.55, Color("a286e9"), 0)
		6:
			cylinder(root, Vector3(0, 2.12, 0), 0.49, 0.3, Color("c4d8e1"))
			g.box(root, Vector3(0, 2.38, 0.02), Vector3(0.09, 0.35, 0.55), Color("ec6e7b"))
			g.box(root, Vector3(-0.58, 1, -0.1), Vector3(0.18, 0.8, 0.55), Color("e5cb86"))
		7:
			for side in [-1, 1]:
				capsule(root, Vector3(side * 0.24, 2.32, 0), 0.06, 0.4, color)
				g.sphere(root, Vector3(side * 0.24, 2.54, 0), 0.11, Color("fffbd1"))
		8:
			for j in range(5): cylinder(root, Vector3(0, 2.1 - j * 0.3, 0.38), 0.14, 0.27, Color("fce495"), 0).rotation.x = PI / 2
			capsule(root, Vector3(0, 0.58, 0.55), 0.14, 0.8, color).rotation.x = PI / 3
		9:
			for side in [-1, 1]: cylinder(root, Vector3(side * 0.31, 2.27, 0), 0.13, 0.5, Color("fff0ce"), 0).rotation.z = -side * 0.35
		10:
			var cape = g.box(root, Vector3(0, 0.99, 0.47), Vector3(0.86, 1.12, 0.07), Color("f36c71"))
			cape.rotation.x = 0.2
			g.sphere(root, Vector3(0, 1.14, -0.37), 0.13, Color("ffe998"))
		11:
			ring(root, Vector3(0, 2.18, 0), 0.36, 0.05, Color("ffcc56"))
			for i in range(5): cylinder(root, Vector3(cos(i * TAU / 5) * 0.32, 2.32, sin(i * TAU / 5) * 0.32), 0.08, 0.32, Color("ffe7a5"), 0)

func build_environment() -> void:
	decor = Node3D.new()
	g.add_child(decor)
	var environment = WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.22
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_density = 0.009
	environment.environment = env
	g.add_child(environment)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 0.46
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	g.add_child(sun)
	road = g.box(g, Vector3(0, -0.34, -84), Vector3(8.4, 0.65, 196), Color.WHITE)
	sea = g.box(g, Vector3(0, -3.5, -95), Vector3(500, 0.5, 500), Color("32bacb"))
	for side in [-1, 1]:
		edge.append(g.box(g, Vector3(side * 4.3, -0.12, -84), Vector3(0.23, 0.65, 196), Color.WHITE))
	for i in range(35):
		var markings = Node3D.new()
		g.add_child(markings)
		markings.position.z = -i * 6
		for x in [-1.4, 1.4]: g.box(markings, Vector3(x, 0.005, 0), Vector3(0.045, 0.018, 1.5), Color(1, 1, 1))
		g.scenery.append(markings)

func set_biome(index: int) -> void:
	biome = index % 6
	var colors = PALETTES[biome]
	env.background_color = Color(colors[0])
	env.fog_light_color = Color(colors[0])
	road.material_override = g.material(Color(colors[2]))
	sea.material_override = g.material(Color(colors[1]))
	for e in edge: e.material_override = g.material(Color(colors[5]))
	for child in decor.get_children(): child.queue_free()
	props.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = 780 + biome
	for i in range(22):
		var island = Node3D.new()
		decor.add_child(island)
		var side = -1 if i % 2 else 1
		island.position = Vector3(side * rng.randf_range(8.0, 17), -1.8, -i * 9.0)
		var base = cylinder(island, Vector3(0, -0.1, 0), rng.randf_range(2.4, 4), 1.6, Color(colors[2]), rng.randf_range(2.8, 4.3))
		base.rotation.y = rng.randf_range(0, 6)
		match biome:
			0: palm(island, Color(colors[4]))
			1:
				for j in range(3):
					var rock = g.sphere(island, Vector3(j * 1.0 - 1, 1.4 + j * 0.5, 0), 1.1, Color(colors[4]).lightened(j * 0.09))
					rock.scale = Vector3(0.85, 1.5 + j * 0.35, 0.85)
			2:
				cylinder(island, Vector3(0, 2, 0), 0.17, 4, Color.WHITE)
				for j in range(3): g.sphere(island, Vector3(j * 0.7 - 0.7, 4 + (j % 2) * 0.5, 0), 1.2, Color(colors[3]).lightened(j * 0.12))
			3:
				for j in range(3): cylinder(island, Vector3(j - 1, 1.8, 0), 0.7, 4 + j, Color(colors[4]).lightened(j * 0.13), 0)
			4:
				g.box(island, Vector3(0, 1.3, 0), Vector3(3, 2.3, 2.5), Color(colors[4]))
				for j in range(2): cylinder(island, Vector3(j * 1.2 - 0.6, 3, 0), 0.3, 2.5, Color(colors[3]))
			5:
				g.box(island, Vector3(0, 2.5, 0), Vector3(2.4, 5, 2.4), Color(colors[4]))
				for j in range(4): g.box(island, Vector3(0, j + 1, 1.22), Vector3(1.8, 0.2, 0.06), Color(colors[3]))
		props.append(island)
	for i in range(12):
		var cloud = Node3D.new()
		decor.add_child(cloud)
		cloud.position = Vector3(rng.randf_range(-55, 55), rng.randf_range(9, 18), -25 - i * 15)
		for j in range(3):
			var puff = g.sphere(cloud, Vector3(j * 2.2, sin(j) * 0.3, 0), 2.1, Color(colors[5]))
			puff.scale = Vector3(1.5, 0.45, 0.65)

func palm(parent: Node3D, color: Color) -> void:
	var trunk = cylinder(parent, Vector3(0, 2.5, 0), 0.2, 5, Color("c48d62"), 0.14)
	trunk.rotation.z = 0.14
	for i in range(6):
		var leaf = g.sphere(parent, Vector3(cos(i * TAU / 6) * 1.1 - 0.35, 4.9, sin(i * TAU / 6) * 1.1), 1, color.lightened((i % 2) * 0.08))
		leaf.scale = Vector3(1.8, 0.17, 0.48)
		leaf.rotation.y = -i * TAU / 6
	for i in range(3): g.sphere(parent, Vector3(-0.3 + i * 0.18, 4.5, 0.1), 0.23, Color("996a4c"))

func move_environment(step: float) -> void:
	for prop in props:
		prop.position.z += step
		if prop.position.z > 17: prop.position.z -= 198

func coin(parent: Node3D, pos: Vector3) -> Node3D:
	var root = Node3D.new()
	parent.add_child(root)
	root.position = pos
	var c = cylinder(root, Vector3.ZERO, 0.3, 0.12, Color("ffc64d"))
	c.rotation.x = PI / 2
	var inset = cylinder(root, Vector3(0, 0, 0.075), 0.22, 0.035, Color("ffe997"))
	inset.rotation.x = PI / 2
	return root

func power_model(parent: Node3D, id: int) -> void:
	var dark = Color("354969")
	var gold = Color("ffcb51")
	match id:
		2:
			g.box(parent, Vector3(0, 0.5, 0), Vector3(1.9, 0.65, 2.6), Color("77c590"))
			cylinder(parent, Vector3(0, 1.0, -0.3), 0.55, 0.5, Color("51a576"))
			capsule(parent, Vector3(0, 1.08, -1.5), 0.14, 2, dark).rotation.x = PI / 2
			for side in [-1, 1]:
				g.box(parent, Vector3(side, 0.3, 0), Vector3(0.48, 0.5, 2.8), dark)
				for j in range(5): cylinder(parent, Vector3(side * 1.24, 0.3, (j - 2) * 0.5), 0.22, 0.06, Color("759086")).rotation.z = PI / 2
		3:
			for side in [-1, 1]:
				capsule(parent, Vector3(side * 0.32, 1.1, 0.45), 0.21, 1.0, Color("f4f4e9"))
				cylinder(parent, Vector3(side * 0.32, 0.3, 0.45), 0.16, 0.65, gold, 0).rotation.x = PI
		10:
			for side in [-1, 1]: capsule(parent, Vector3(side * 0.23, -1.1, 0), 0.18, 2.3, gold)
		11:
			for side in [-1, 1]:
				capsule(parent, Vector3(side * 0.62, 1.2, -1.8), 0.16, 3.8, gold).rotation.x = PI / 2
				g.sphere(parent, Vector3(side * 0.62, 1.2, -3.7), 0.32, Color("ff895e"))
		14:
			capsule(parent, Vector3(0, 0.6, 0), 0.6, 3.7, Color("ff765a")).rotation.x = PI / 2
			for side in [-1, 1]: g.box(parent, Vector3(side * 0.7, 0.6, 0.6), Vector3(1.3, 0.15, 0.8), gold)
			cylinder(parent, Vector3(0, 0.6, 2.4), 0.4, 1.2, gold, 0).rotation.x = PI / 2
		15:
			for j in range(7): ring(parent, Vector3(0, 1.5, -0.4 - j * 0.35), 0.13, 0.045, dark).rotation.x = PI / 2
			g.sphere(parent, Vector3(0, 1.5, -3), 0.85, Color("5d7390"))
		16:
			capsule(parent, Vector3(0, 0.3, 0), 0.65, 2.6, Color("76cc8b")).rotation.x = PI / 2
			g.sphere(parent, Vector3(0, 0.8, -1.35), 0.6, Color("76cc8b"))
			for side in [-1, 1]:
				var wing = cylinder(parent, Vector3(side * 1.4, 0.5, 0.1), 1.3, 0.09, Color("ffd38d"), 0)
				wing.rotation.z = side * 0.3
				g.sphere(parent, Vector3(side * 0.3, 1.06, -1.8), 0.08, dark)
		17:
			capsule(parent, Vector3(0.6, 1.7, -1.6), 0.13, 2.3, Color("c08952")).rotation.x = -0.5
			g.box(parent, Vector3(0.6, 2.65, -2.1), Vector3(1.9, 1.0, 0.9), gold)
		13:
			costume(parent, 9, Color("ff785b"))
		18:
			costume(parent, 10, gold)
		_:
			if id in [0, 1]: ring(parent, Vector3(0, 0.04, 0), 0.8, 0.065, gold)
			elif id in [4, 19]:
				for side in [-1, 1]: capsule(parent, Vector3(side * 0.16, 1.86, -5), 0.055 if id == 4 else 0.14, 9.5, Color("ff677b")).rotation.x = PI / 2
			elif id in [5, 8, 9, 12]:
				var halo = ring(parent, Vector3(0, 0.8, 0), 1.0, 0.06, Color("6bddeb") if id in [5, 8] else gold)
				if id == 12: halo.rotation.x = PI / 2
