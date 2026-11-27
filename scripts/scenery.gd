class_name Scenery
## The decors of the 3D scenes, built from the Quaternius models.
## Positions are in metres: x to the right, z towards the player; the fight
## takes place around 0.

const TILE := 2.0


## Replaces the decor of a stage: "forge", or the backdrop of a zone of the catalog.
static func build(stage: Stage3D, id: String) -> void:
	stage.clear_scenery()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	match id:
		"canyon":
			stage.light(Color(0.75, 0.68, 0.75), 0.4, Color(1.0, 0.84, 0.62), 0.8, Color("e6c79c"), 0.014)
			_ground(stage, "sand", Color(0.8, 0.78, 0.75))
			# Cliffs behind and on both sides, boulders in front of them.
			for index in 14:
				_rock(stage, index, Vector3(-13.0 + index * 2.0 + rng.randf_range(-0.5, 0.5), -0.4, rng.randf_range(-9.5, -6.0)), rng.randf_range(5.0, 9.0), "Rocks_Desert", rng)
			for side in [-1.0, 1.0]:
				for index in 5:
					_rock(stage, index, Vector3(side * rng.randf_range(8.0, 10.5), -0.3, -4.5 + index * 1.6), rng.randf_range(1.6, 2.8), "Rocks_Desert", rng)
			for index in 18:
				_rock(stage, index, Vector3(rng.randf_range(-6.5, 6.5), -0.05, rng.randf_range(-5.0, -2.6)), rng.randf_range(0.5, 1.4), "Rocks_Desert", rng)
			for index in 7:
				put(stage, "nature/DeadTree_%d.fbx" % (index % 6 + 1), Vector3(rng.randf_range(-8.0, 8.0), 0, rng.randf_range(-6.0, -3.0)), rng.randf_range(0, 360), rng.randf_range(0.6, 1.0))
			for index in 12:
				put(stage, "nature/Bush_Small.fbx" if index % 2 else "nature/Bush.fbx", _around(rng), rng.randf_range(0, 360), rng.randf_range(0.8, 1.4), Color(1.3, 1.0, 0.5))
			put(stage, "modular_dungeon_pack/Bones.glb", Vector3(-3.6, 0, -1.9), 40, 1.2)
			put(stage, "modular_dungeon_pack/Bones2.glb", Vector3(3.8, 0, -2.6), 200, 1.2)
			put(stage, "rpg_items_pack/Skull.glb", Vector3(4.6, 0.05, 4.9), 30, 2.0)
		"castle":
			stage.light(Color(0.55, 0.68, 0.9), 0.45, Color(1.0, 0.9, 0.72), 0.95, Color("a9cbe6"), 0.012)
			_ground(stage, "grass", Color.WHITE)
			for spot in [["House_1", -6.5, -8.0, 20, 2.2], ["Inn", 1.5, -10.0, -10, 2.2], ["Bell_Tower", 8.0, -9.0, 0, 2.3],
					["House_2", -12.5, -10.0, 40, 2.2], ["House_3", 13.0, -11.0, -30, 2.2], ["Stable", -1.5, -14.0, 0, 2.2],
					["Well", -2.2, -4.6, 0, 1.5], ["Cart", 4.8, -3.4, 60, 1.4], ["Hay", -5.0, -3.6, 0, 1.5], ["Hay", -5.9, -3.2, 50, 1.3],
					["MarketStand_1", 7.2, -4.8, -30, 1.5], ["Barrel", 3.6, -3.9, 0, 1.4], ["Crate", 5.9, -2.6, 20, 1.4], ["Bags", -3.6, -3.2, 0, 1.4]]:
				put(stage, "medieval_village_pack/%s.glb" % spot[0], Vector3(spot[1], 0, spot[2]), spot[3], spot[4])
			for index in 9:
				put(stage, "medieval_village_pack/Fence.glb", Vector3(-9.0 + index * 2.2, 0, -5.6), 0, 1.4)
			for index in 26:
				var kind: String = ["NormalTree_%d", "BirchTree_%d", "NormalTree_%d", "PineTree_%d"][index % 4] % (index % 3 + 1)
				put(stage, "nature/%s.fbx" % kind, Vector3(rng.randf_range(-16.0, 16.0), 0, rng.randf_range(-18.0, -11.0) if index % 3 else rng.randf_range(-9.0, -6.5)), rng.randf_range(0, 360), rng.randf_range(0.9, 1.4))
			for side in [-1.0, 1.0]:
				for index in 4:
					put(stage, "nature/NormalTree_%d.fbx" % (index + 1), Vector3(side * rng.randf_range(7.5, 10.0), 0, -3.0 + index * 2.4), rng.randf_range(0, 360), rng.randf_range(0.8, 1.1))
			for index in 16:
				put(stage, ["nature/Bush.fbx", "nature/Bush_Flowers.fbx", "nature/Bush_Large.fbx", "nature/Bush_Small.fbx"][index % 4], _around(rng), rng.randf_range(0, 360), rng.randf_range(0.8, 1.5), Color(0.55, 0.7, 0.45))
			for index in 26:
				put(stage, ["nature/Flower_1_Clump.fbx", "nature/Flower_2_Clump.fbx", "nature/Plant_1.fbx", "nature/Plant_2.fbx"][index % 4], _around(rng, 1.6), rng.randf_range(0, 360), rng.randf_range(0.8, 1.3))
			for index in 6:
				_rock(stage, index, _around(rng), rng.randf_range(0.4, 0.9), "Rocks", rng)
		"temple":
			stage.light(Color(0.6, 0.58, 0.8), 0.5, Color(1.0, 0.8, 0.62), 0.6, Color("15121c"), 0.015, -160.0)
			_room(stage, Color.WHITE, -5.0, 3)
			for x in [-7.0, -3.5, 3.5, 7.0]:
				put(stage, "modular_dungeon_1/Column.glb", Vector3(x, 0, -3.6), 0, 1.3)
			for x in [-5.2, 0.0, 5.2]:
				_torch(stage, Vector3(x, 2.4, -4.8), Color(1.0, 0.55, 0.25))
			for spot in [["modular_dungeon_1/Statue_Horse.glb", -5.6, -3.4, 30, 1.3], ["modular_dungeon_1/Statue_Horse.glb", 5.6, -3.4, -30, 1.3],
					["modular_dungeon_1/Banner_wall.glb", -1.8, -4.85, 0, 1.4], ["modular_dungeon_1/Banner_wall.glb", 1.8, -4.85, 0, 1.4],
					["modular_dungeon_pack/Candelabrum_tall.glb", -1.4, -3.6, 0, 1.3],
					["modular_dungeon_pack/Candelabrum_tall.glb", 1.4, -3.6, 0, 1.3],
					["modular_dungeon_1/Vase.glb", -6.6, -1.6, 0, 1.3], ["modular_dungeon_1/Vase.glb", 6.4, -2.2, 0, 1.3],
					["modular_dungeon_1/Chest_Gold.glb", 7.4, -3.2, -30, 1.2], ["modular_dungeon_pack/Column_Broken.glb", -8.2, -1.8, 0, 1.3]]:
				put(stage, spot[0], Vector3(spot[1], 0, spot[2]), spot[3], spot[4])
		"depths":
			stage.light(Color(0.45, 0.6, 0.95), 0.75, Color(0.7, 0.85, 1.0), 0.75, Color("0b0e1a"), 0.02, -170.0)
			_ground(stage, "cave", Color.WHITE)
			for index in 16:
				_rock(stage, index, Vector3(-14.0 + index * 1.9, -0.5, rng.randf_range(-8.5, -5.0)), rng.randf_range(5.0, 9.0), "Rocks_Dark_Green", rng)
			for side in [-1.0, 1.0]:
				for index in 5:
					_rock(stage, index, Vector3(side * rng.randf_range(8.0, 10.5), -0.3, -4.5 + index * 1.6), rng.randf_range(1.6, 2.8), "Rocks_Dark_Green", rng)
			for index in 14:
				_rock(stage, index, _around(rng), rng.randf_range(0.5, 1.3), "Rocks_Dark_Green", rng)
			var colors := [Color(0.3, 0.9, 1.0), Color(0.75, 0.4, 1.0), Color(0.3, 1.0, 0.6)]
			for index in 9:
				var at := Vector3(rng.randf_range(-7.0, 7.0), 0, rng.randf_range(-5.0, -2.4)) if index % 3 else _around(rng)
				var crystal := put(stage, "rpg_items_pack/Crystal%d.glb" % (index % 3 + 1), at, rng.randf_range(0, 360), rng.randf_range(3.0, 6.0))
				_glowing(crystal, colors[index % 3])
				_lamp(stage, at + Vector3(0, 1.0, 0.4), colors[index % 3], 1.2, 5.0)
			put(stage, "modular_dungeon_pack/Column_Broken2.glb", Vector3(-5.0, 0, -2.8), 20, 1.4)
			put(stage, "modular_dungeon_pack/Bones.glb", Vector3(4.2, 0, -2.2), 120, 1.2)
			put(stage, "modular_dungeon_pack/Bones2.glb", Vector3(-4.4, 0, 4.9), 0, 1.2)
		"forge":
			stage.light(Color(0.6, 0.6, 0.78), 0.45, Color(1.0, 0.88, 0.72), 0.55, Color("14121c"), 0.0, -160.0)
			_room(stage, Color(1.25, 0.95, 0.75), -2.6, 2)
			for spot in [["modular_dungeon_1/Barrel.glb", -4.6, -1.9, 0, 1.2], ["modular_dungeon_1/Barrel2.glb", -3.8, -2.1, 0, 1.2],
					["modular_dungeon_1/Crate.glb", 4.9, -1.9, 15, 1.2], ["modular_dungeon_1/Crate.glb", 5.0, -1.85, 40, 0.9, 0.95],
					["modular_dungeon_1/Table_Big.glb", 1.2, -1.9, 0, 1.2], ["modular_dungeon_1/Bucket.glb", 2.9, -1.6, 0, 1.2],
					["rpg_items_pack/Gold_Ingots.glb", 1.0, -1.9, 20, 1.0, 0.95], ["rpg_items_pack/Chest_Ingots.glb", -5.2, 0.0, 70, 1.6],
					["props/Stool.gltf", 3.6, -0.6, 0, 1.0], ["modular_dungeon_1/Sword_WallMount.glb", -1.2, -2.5, 0, 1.3, 1.9],
					["modular_dungeon_1/Banner_wall.glb", 4.0, -2.5, 0, 1.2, 0.3]]:
				put(stage, spot[0], Vector3(spot[1], spot[5] if spot.size() > 5 else 0.0, spot[2]), spot[3], spot[4])
			_torch(stage, Vector3(2.6, 2.1, -2.4), Color(1.0, 0.6, 0.3))


## A model placed on the stage.
static func put(stage: Stage3D, file: String, at: Vector3, turn := 0.0, size := 1.0, tint := Color.WHITE) -> Node3D:
	var node := Models.model(file)
	node.position = at
	node.rotation_degrees.y = turn
	node.scale *= size
	if tint != Color.WHITE:
		for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
			for surface in mesh.mesh.get_surface_count():
				var kind := String(mesh.mesh.surface_get_material(surface).resource_name)
				if Models.NATURE.has(kind):
					mesh.set_surface_override_material(surface, Models._nature(Models.NATURE[kind], tint))
	stage.scenery.add_child(node)
	return node


## A rock of the nature pack, with one of its three pictures (grey, desert, mossy).
static func _rock(stage: Stage3D, index: int, at: Vector3, size: float, picture: String, rng: RandomNumberGenerator) -> void:
	var node := put(stage, "nature/Rock_%d.fbx" % (index % 5 + 1), at, rng.randf_range(0, 360), size)
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		mesh.set_surface_override_material(0, Models._nature(picture))


## A point around the place of the fight, not on it.
static func _around(rng: RandomNumberGenerator, edge := 3.2) -> Vector3:
	while true:
		var at := Vector3(rng.randf_range(-8.0, 8.0), 0, rng.randf_range(-5.5, 6.5))
		if absf(at.x) > edge + 1.6 or at.z < -2.4:
			return at
	return Vector3.ZERO


static func _lamp(stage: Stage3D, at: Vector3, color: Color, power: float, reach: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = at
	lamp.light_color = color
	lamp.light_energy = power
	lamp.omni_range = reach
	stage.scenery.add_child(lamp)


## A wall torch with its light.
static func _torch(stage: Stage3D, at: Vector3, color: Color) -> void:
	put(stage, "modular_dungeon_pack/Torch_wall.glb", at, 0, 1.3)
	_lamp(stage, at + Vector3(0, 0.5, 0.7), color, 1.6, 7.0)


## Makes a model shine with a colour.
static func _glowing(node: Node3D, color: Color) -> void:
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var paint := StandardMaterial3D.new()
			paint.albedo_color = color
			paint.emission_enabled = true
			paint.emission = color
			paint.emission_energy_multiplier = 0.9
			mesh.set_surface_override_material(surface, paint)


## A floor of stone tiles and a back wall, for the scenes indoors.
static func _room(stage: Stage3D, tint: Color, back: float, rows: int) -> void:
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 30)
	var paint := StandardMaterial3D.new()
	paint.albedo_texture = load(Models.DIR + "ground/stone.png")
	paint.albedo_color = tint
	paint.uv1_scale = Vector3(10, 7.5, 1)
	paint.roughness = 0.9
	plane.material = paint
	floor.mesh = plane
	stage.scenery.add_child(floor)
	for row in rows:
		for x in range(-7, 8):
			var wall := put(stage, "modular_dungeon_1/Wall_Modular.glb", Vector3(x * TILE, row * TILE, back))
			if tint != Color.WHITE:
				for mesh: MeshInstance3D in wall.find_children("*", "MeshInstance3D", true, false):
					for surface in mesh.mesh.get_surface_count():
						Models._tint_surface(mesh, surface, (mesh.mesh.surface_get_material(surface) as StandardMaterial3D).albedo_color * tint)


## One wide ground with a picture of assets/quaternius/ground repeated on it.
static func _ground(stage: Stage3D, picture: String, tint: Color) -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	var paint := StandardMaterial3D.new()
	paint.albedo_texture = load(Models.DIR + "ground/%s.png" % picture)
	paint.albedo_color = tint
	paint.uv1_scale = Vector3(8, 8, 1)
	paint.roughness = 1.0
	plane.material = paint
	ground.mesh = plane
	stage.scenery.add_child(ground)
