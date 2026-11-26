class_name Scenery
## The decors of the 3D scenes, built from the KayKit models of assets/kaykit/props.
## Positions are in metres: x to the right, z towards the player, 0 at the middle
## of the picture.

const DIR := "res://assets/kaykit/props/"
const TILE := 4.0


## Replaces the decor of a stage: "forge", or the backdrop of a zone of the catalog.
static func build(stage: Stage3D, id: String) -> void:
	stage.clear_scenery()
	match id:
		"canyon":
			stage.light(Color(0.75, 0.7, 0.8), 0.55, Color(1.0, 0.9, 0.72), 1.05, Color("e9b98a"))
			_plain(stage, Color("6b5238"))
			for spot in [[-5.5, -7.5, "mountain_A", 2.6, 20], [0.5, -9.0, "mountain_B", 3.0, 0], [5.5, -7.0, "mountain_C", 2.4, -30],
					[-2.6, -5.2, "rock_single_D", 2.2, 0], [3.0, -5.6, "rock_single_E", 2.4, 40], [-4.6, -2.0, "rock_single_A", 1.8, 0],
					[4.9, 0.5, "rock_single_B", 1.6, 80], [-4.9, 3.5, "rock_single_C", 1.7, 10], [4.6, 5.0, "rock_single_A", 1.5, 200],
					[0.4, -2.6, "rock_single_C", 1.3, 120], [-1.5, 6.5, "rock_single_E", 1.2, 0]]:
				_tinted(prop(stage, spot[2], Vector3(spot[0], 0, spot[1]), spot[4], spot[3]), Color(0.95, 0.66, 0.45))
		"castle":
			stage.light(Color(0.7, 0.8, 1.0), 0.6, Color(1.0, 0.97, 0.88), 1.0, Color("9fd0f0"))
			_plain(stage, Color("3a5730"))
			prop(stage, "building_castle_red", Vector3(0.6, 0, -8.5), 0, 4.2)
			prop(stage, "building_tower_A_red", Vector3(-5.0, 0, -6.5), 20, 3.4)
			for spot in [[-2.4, -5.0, "trees_A_large", 2.4, 0], [4.9, -5.4, "trees_B_large", 2.6, 50], [-5.2, -2.6, "tree_single_A", 2.4, 0],
					[5.2, -1.5, "tent", 2.6, -35], [-4.7, 2.5, "weaponrack", 2.4, 60], [5.0, 3.5, "flag_red", 2.6, 0],
					[-5.0, 5.6, "rock_single_B", 1.4, 0], [1.2, -4.6, "target", 2.4, 10]]:
				prop(stage, spot[2], Vector3(spot[0], 0, spot[1]), spot[4], spot[3])
		"temple":
			stage.light(Color(0.55, 0.5, 0.85), 0.5, Color(1.0, 0.85, 0.7), 0.6, Color("14121c"))
			_room(stage, "floor_tile_large", ["wall", "wall_arched", "wall_cracked", "wall_arched", "wall"], -4.6)
			for x in [-2.0, 2.0]:
				_torch(stage, Vector3(x, 1.7, -4.1))
			for spot in [[-3.9, -3.6, "pillar_decorated", 0], [3.9, -3.6, "pillar_decorated", 0], [-4.1, 1.0, "column", 0],
					[4.1, 3.5, "column", 0], [0.0, -3.7, "banner_shield_red", 0], [3.9, -1.0, "candle_triple", 0]]:
				prop(stage, spot[2], Vector3(spot[0], 0, spot[1]), spot[3])
		"depths":
			stage.light(Color(0.35, 0.45, 0.75), 0.45, Color(0.7, 0.8, 1.0), 0.45, Color("0b0a12"))
			_room(stage, "floor_dirt_large", ["wall_broken", "wall_cracked", "wall_arched", "wall", "wall_broken"], -4.6)
			_torch(stage, Vector3(0.0, 1.7, -4.1), Color(0.4, 0.8, 1.0))
			for spot in [[-3.8, -3.4, "rubble_half", 0], [3.6, -3.2, "column", 0], [-4.2, 0.5, "trunk_large_A", 70],
					[4.2, 2.0, "rubble_half", 140], [-3.9, 4.8, "column", 0], [3.9, 5.5, "chest_gold", -60]]:
				prop(stage, spot[2], Vector3(spot[0], 0, spot[1]), spot[3])
		"forge":
			stage.light(Color(0.65, 0.65, 0.8), 0.5, Color(1.0, 0.92, 0.8), 0.6, Color("14121c"))
			_room(stage, "floor_wood_large", ["wall", "wall_shelves", "wall", "wall_window_closed", "wall"], -1.7)
			for spot in [[-4.0, -1.0, "barrel_small_stack", 0], [0.2, -1.1, "crates_stacked", 10], [3.9, -1.1, "keg", -90]]:
				prop(stage, spot[2], Vector3(spot[0], 0, spot[1]), spot[3], 0.85)


## A KayKit model placed on the stage.
static func prop(stage: Stage3D, file: String, at: Vector3, turn := 0.0, size := 1.0) -> Node3D:
	var path := ""
	for ending in [".gltf.glb", ".glb", ".gltf"]:
		if ResourceLoader.exists(DIR + file + ending):
			path = DIR + file + ending
	var node: Node3D = (load(path) as PackedScene).instantiate()
	node.position = at
	node.rotation_degrees.y = turn
	node.scale = Vector3.ONE * size
	stage.scenery.add_child(node)
	return node


## A wall torch with its light.
static func _torch(stage: Stage3D, at: Vector3, color := Color(1.0, 0.6, 0.25)) -> void:
	prop(stage, "torch_mounted", at)
	var fire := OmniLight3D.new()
	fire.position = at + Vector3(0, 0.9, 0.5)
	fire.light_color = color
	fire.light_energy = 1.1
	fire.omni_range = 6.5
	stage.scenery.add_child(fire)


## A floor of tiles and a back wall, for the scenes indoors.
static func _room(stage: Stage3D, floor: String, walls: Array, back: float) -> void:
	for x in range(-2, 3):
		for z in range(-2, 4):
			prop(stage, floor, Vector3(x * TILE, 0, z * TILE))
	for index in walls.size():
		prop(stage, walls[index], Vector3((index - walls.size() / 2) * TILE, 0, back))


## One flat ground, for the scenes outdoors.
static func _plain(stage: Stage3D, color: Color) -> void:
	var ground := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(60, 60)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	paint.roughness = 1.0
	mesh.material = paint
	ground.mesh = mesh
	stage.scenery.add_child(ground)


## Multiplies the colours of a model (grey rocks become red rocks).
static func _tinted(node: Node3D, color: Color) -> void:
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var original := mesh.get_active_material(0) as StandardMaterial3D
		if original:
			var painted: StandardMaterial3D = original.duplicate()
			painted.albedo_color = color
			mesh.set_surface_override_material(0, painted)
