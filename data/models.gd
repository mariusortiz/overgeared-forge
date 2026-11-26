class_name Models
## The 3D models of the game (KayKit, CC0; see tools/build_kaykit.py).

const DIR := "res://assets/kaykit/"
const METAL := preload("res://assets/metal.gdshader")

## model: a file of assets/kaykit/characters; skin: a picture of assets/kaykit/skins;
## size: 1 by default; hide: parts of the model not shown; weapon: a key of WEAPONS.
const CHARACTERS := {
	"grid": {"model": "Rogue", "skin": "grid", "hide": ["Rogue_Cape"]},
	"grid_armor": {"model": "Knight", "skin": "grid_armor", "hide": ["Knight_Helmet"]},
	"goblin": {"model": "Rogue_Hooded", "skin": "goblin", "size": 0.8, "hide": ["Rogue_Cape"], "weapon": "dagger"},
	"skeleton": {"model": "Skeleton_Minion", "skin": "skeleton", "weapon": "bone_blade"},
	"orc": {"model": "Barbarian", "skin": "orc", "size": 1.12, "weapon": "axe"},
	"soldier": {"model": "Knight", "skin": "soldier", "weapon": "spear"},
	"mercenary": {"model": "Rogue", "skin": "mercenary", "weapon": "dagger"},
	"knight": {"model": "Knight", "skin": "knight", "size": 1.1, "weapon": "great_sword"},
	"cultist": {"model": "Rogue_Hooded", "skin": "cultist", "weapon": "dagger"},
	"zealot": {"model": "Mage", "skin": "zealot", "weapon": "hammer"},
	"dark_priest": {"model": "Mage", "skin": "dark_priest", "weapon": "staff"},
	"rival": {"model": "Knight", "skin": "rival", "hide": ["Knight_Helmet"], "weapon": "sword"},
	"orc_chief": {"model": "Barbarian", "skin": "orc_chief", "size": 1.1, "weapon": "great_axe"},
	"captain": {"model": "Knight", "skin": "captain", "weapon": "great_sword"},
	"malacus": {"model": "Skeleton_Mage", "skin": "malacus", "weapon": "bone_staff"},
}

## The weapons and tools the models come with in their hands: never shown.
const HELD := [
	"1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Round_Shield", "Spike_Shield", "1H_Sword", "2H_Sword",
	"Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Knife", "Throwable", "1H_Axe_Offhand", "Barbarian_Round_Shield",
	"1H_Axe", "2H_Axe", "Mug", "Spellbook", "Spellbook_open", "1H_Wand", "2H_Staff",
]

## file: a model of assets/kaykit/weapons, or built: a shape made in _build();
## attack and idle: the animations of the character who holds it.
const WEAPONS := {
	"sword": {"file": "sword_1handed", "attack": "1H_Melee_Attack_Chop"},
	"dagger": {"file": "dagger", "attack": "1H_Melee_Attack_Stab"},
	"axe": {"file": "axe_1handed", "attack": "1H_Melee_Attack_Chop"},
	"spear": {"built": "spear", "attack": "1H_Melee_Attack_Stab"},
	"hammer": {"built": "hammer", "attack": "1H_Melee_Attack_Chop"},
	"scythe": {"built": "scythe", "attack": "2H_Melee_Attack_Slice", "idle": "2H_Melee_Idle"},
	"shield": {"file": "shield_round", "attack": "Block_Attack"},
	"plate": {"built": "plate", "attack": "1H_Melee_Attack_Chop"},
	"great_sword": {"file": "sword_2handed", "attack": "2H_Melee_Attack_Chop", "idle": "2H_Melee_Idle"},
	"great_axe": {"file": "axe_2handed", "attack": "2H_Melee_Attack_Chop", "idle": "2H_Melee_Idle"},
	"staff": {"file": "staff", "attack": "Spellcast_Shoot"},
	"bone_blade": {"file": "Skeleton_Blade", "attack": "1H_Melee_Attack_Slice_Diagonal"},
	"bone_staff": {"file": "Skeleton_Staff", "attack": "Spellcast_Shoot"},
}

const WOOD := Color("8a5a3a")
const STEEL := Color("aab2b8")


static func character(id: String) -> Node3D:
	var info: Dictionary = CHARACTERS[id]
	var node: Node3D = (load(DIR + "characters/%s.glb" % info.model) as PackedScene).instantiate()
	var skin: Texture2D = load(DIR + "skins/%s.png" % info.skin)
	for part in HELD + info.get("hide", []):
		var found := node.find_child(part, true, false)
		if found:
			found.visible = false
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var original := mesh.get_active_material(0) as StandardMaterial3D
		if original and original.albedo_texture:
			var painted: StandardMaterial3D = original.duplicate()
			painted.albedo_texture = skin
			mesh.set_surface_override_material(0, painted)
	return node


## A weapon to put in a hand or on the anvil. With a material, its metal takes
## the material's colours and the rarity's glow.
static func weapon(key: String, material := "", rarity := 0) -> Node3D:
	var info: Dictionary = WEAPONS[key]
	var node: Node3D
	if info.has("file"):
		node = (load(DIR + "weapons/%s.gltf" % info.file) as PackedScene).instantiate()
	else:
		node = _build(info.built)
	if material != "":
		dress(node, material, rarity)
	return node


## Gives every mesh under a node the colours of a material and of a rarity.
static func dress(node: Node, material: String, rarity: int, only: Array = []) -> void:
	var meshes := node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	for mesh: MeshInstance3D in meshes:
		if not only.is_empty() and mesh.name not in only:
			continue
		var original := mesh.get_active_material(0) as StandardMaterial3D
		if original == null:
			continue
		var shader := ShaderMaterial.new()
		shader.shader = METAL
		shader.set_shader_parameter("albedo", original.albedo_texture)
		shader.set_shader_parameter("base", original.albedo_color)
		var mat: Dictionary = Catalog.MATERIALS[material]
		shader.set_shader_parameter("metal_dark", mat.dark)
		shader.set_shader_parameter("metal_light", mat.light)
		if rarity > 0:
			shader.set_shader_parameter("glow", Catalog.RARITIES[rarity].color)
			shader.set_shader_parameter("glow_power", 0.35 + rarity * 0.2)
		mesh.set_surface_override_material(0, shader)


## Frees a model. Its materials are taken off first: freed with the meshes that
## use them, they leave an error in the log.
static func discard(node: Node) -> void:
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		mesh.set_surface_override_material(0, null)
	node.queue_free()


## Sets the heat (0 to 1) of everything dressed under a node.
static func set_heat(node: Node, heat: float) -> void:
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var shader := mesh.get_surface_override_material(0) as ShaderMaterial
		if shader:
			shader.set_shader_parameter("heat", heat)


# --- Shapes the packs do not have, made of simple blocks ---------------------
# Like the pack's weapons: the handle is at the origin, the head points up.

static func _build(shape: String) -> Node3D:
	var node := Node3D.new()
	match shape:
		"spear":
			_part(node, _rod(0.035, 1.9), WOOD, Vector3(0, 0.45, 0))
			_part(node, _spike(0.11, 0.42), STEEL, Vector3(0, 1.6, 0), Vector3.ZERO, Vector3(1, 1, 0.35))
			_part(node, _rod(0.06, 0.08), STEEL, Vector3(0, 1.38, 0))
		"hammer":
			_part(node, _rod(0.04, 0.95), WOOD, Vector3(0, 0.3, 0))
			_part(node, _block(Vector3(0.52, 0.3, 0.3)), STEEL, Vector3(0, 0.82, 0))
			_part(node, _block(Vector3(0.1, 0.36, 0.36)), STEEL, Vector3(0.28, 0.82, 0))
			_part(node, _block(Vector3(0.1, 0.36, 0.36)), STEEL, Vector3(-0.28, 0.82, 0))
		"scythe":
			_part(node, _rod(0.04, 2.0), WOOD, Vector3(0, 0.5, 0))
			_part(node, _spike(0.26, 0.95), STEEL, Vector3(0.44, 1.4, 0), Vector3(0, 0, -98), Vector3(1, 1, 0.14))
			_part(node, _rod(0.07, 0.1), STEEL, Vector3(0, 1.45, 0))
		"plate":
			_part(node, _ball(0.36), STEEL, Vector3(0, 0.45, 0), Vector3.ZERO, Vector3(1.0, 1.2, 0.62))
			_part(node, _ball(0.13), STEEL, Vector3(0.36, 0.62, 0), Vector3.ZERO, Vector3(1.3, 0.7, 1.2))
			_part(node, _ball(0.13), STEEL, Vector3(-0.36, 0.62, 0), Vector3.ZERO, Vector3(1.3, 0.7, 1.2))
			_part(node, _block(Vector3(0.6, 0.1, 0.42)), WOOD, Vector3(0, 0.06, 0))
	return node


static func _part(parent: Node3D, mesh: Mesh, color: Color, at: Vector3, turn := Vector3.ZERO, stretch := Vector3.ONE) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	paint.roughness = 0.7
	(mesh as PrimitiveMesh).material = paint
	part.position = at
	part.rotation_degrees = turn
	part.scale = stretch
	parent.add_child(part)
	return part


static func _rod(radius: float, length: float) -> Mesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 6
	mesh.rings = 1
	return mesh


static func _spike(radius: float, length: float) -> Mesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 4
	mesh.rings = 1
	return mesh


static func _block(size: Vector3) -> Mesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func _ball(radius: float) -> Mesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	return mesh
