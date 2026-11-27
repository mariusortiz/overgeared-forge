class_name Models
## The 3D models of the game (Quaternius, CC0; see tools/build_quaternius.py).

const DIR := "res://assets/quaternius/"
const METAL := preload("res://assets/metal.gdshader")

## The free pack has two outfits, for men and for women: every character is one
## of them, told apart by its colours, its hair, its size and its weapon.
## outfit: a file of assets/quaternius/characters;
## head: true when the outfit comes without a head (taken from the base character);
## hair and hair_color; skin and cloth: colours multiplied with the pictures;
## hide: parts of the outfit not shown; armor: pieces of the ranger outfit added;
## size: 1 by default; weapon: a key of WEAPONS.
const BROWN := Color("5a3620")
const CHARACTERS := {
	"grid": {"outfit": "Male_Peasant", "head": true, "hair": "Hair_SimpleParted", "hair_color": BROWN},
	"grid_armor": {"outfit": "Male_Peasant", "head": true, "hair": "Hair_SimpleParted", "hair_color": BROWN,
		"armor": ["Male_Ranger_Acc_Pauldron", "Male_Ranger_Arms_Bracer", "Male_Ranger_Body_Belt_1"]},
	"goblin": {"outfit": "Male_Ranger", "skin": Color(0.55, 1.0, 0.4), "cloth": Color(0.8, 0.65, 0.5), "size": 0.72,
		"hide": ["Male_Ranger_Acc_Pauldron"], "weapon": "dagger"},
	"skeleton": {"outfit": "Male_Peasant", "head": true, "skin": Color(0.62, 0.8, 0.85), "cloth": Color(0.45, 0.45, 0.55),
		"weapon": "sword"},
	"orc": {"outfit": "Male_Peasant", "head": true, "hair": "Hair_Buzzed", "hair_color": Color("1c1c1c"),
		"skin": Color(0.5, 0.85, 0.35), "cloth": Color(0.6, 0.45, 0.35), "size": 1.16, "weapon": "axe"},
	"soldier": {"outfit": "Male_Ranger", "head": true, "hair": "Hair_Buzzed", "hair_color": Color("3a2a1c"),
		"hide": ["Male_Ranger_Head_Hood"], "cloth": Color(0.55, 0.75, 1.3), "weapon": "spear"},
	"mercenary": {"outfit": "Female_Ranger", "cloth": Color(1.2, 0.7, 0.5), "weapon": "dagger"},
	"knight": {"outfit": "Male_Ranger", "head": true, "hair": "Hair_Beard", "hair_color": Color("2a2a2a"),
		"hide": ["Male_Ranger_Head_Hood"], "cloth": Color(0.5, 0.5, 0.6), "size": 1.08, "weapon": "great_sword"},
	"cultist": {"outfit": "Male_Ranger", "cloth": Color(0.85, 0.45, 1.3), "hide": ["Male_Ranger_Acc_Pauldron"], "weapon": "dagger"},
	"zealot": {"outfit": "Male_Peasant", "head": true, "hair": "Hair_Beard", "hair_color": Color("7a2a14"),
		"cloth": Color(1.4, 0.4, 0.35), "weapon": "hammer"},
	"dark_priest": {"outfit": "Female_Ranger", "cloth": Color(0.35, 0.3, 0.45), "skin": Color(0.8, 0.82, 0.95),
		"hide": ["Female_Ranger_Acc_Pauldrons"], "weapon": "staff"},
	"rival": {"outfit": "Female_Peasant", "head": true, "female": true, "hair": "Hair_Long", "hair_color": Color("d9b25a"),
		"cloth": Color(0.7, 0.9, 1.3), "weapon": "sword"},
	"orc_chief": {"outfit": "Male_Peasant", "head": true, "hair": "Hair_Beard", "hair_color": Color("1c1c1c"),
		"skin": Color(0.42, 0.72, 0.3), "cloth": Color(0.75, 0.3, 0.25), "size": 1.0,
		"armor": ["Male_Ranger_Acc_Pauldron", "Male_Ranger_Arms_Bracer"], "weapon": "great_axe"},
	"captain": {"outfit": "Male_Ranger", "head": true, "hair": "Hair_SimpleParted", "hair_color": Color("d9b25a"),
		"hide": ["Male_Ranger_Head_Hood"], "cloth": Color(1.5, 1.25, 0.6), "size": 0.95, "weapon": "great_sword"},
	"malacus": {"outfit": "Male_Ranger", "cloth": Color(0.9, 0.25, 0.3), "skin": Color(0.75, 0.75, 0.9), "size": 0.98,
		"weapon": "staff"},
}

## file: a model of assets/quaternius; grow: how much larger it is shown;
## built: a shape made in _build(); attack: the animation of who holds it.
const WEAPONS := {
	"sword": {"file": "props/Sword_Bronze.gltf", "attack": "Sword_Attack"},
	"dagger": {"file": "props/Dagger_Bronze.gltf", "attack": "Sword_Attack"},
	"axe": {"file": "props/Axe_Bronze.gltf", "attack": "Sword_Attack"},
	"hammer": {"file": "props/Hammer_Medium_Bronze.gltf", "attack": "Sword_Attack"},
	"shield": {"file": "props/Shield_Wooden.gltf", "attack": "Sword_Attack"},
	"spear": {"built": "spear", "attack": "Sword_Attack"},
	"scythe": {"built": "scythe", "attack": "Sword_Attack"},
	"plate": {"file": "rpg_items_pack/Armor_Metal.glb", "attack": "Sword_Attack"},
	"great_sword": {"file": "props/Sword_Bronze.gltf", "grow": 1.25, "attack": "Sword_Attack"},
	"great_axe": {"file": "props/Axe_Double_Bronze.gltf", "grow": 1.2, "attack": "Sword_Attack"},
	"staff": {"built": "staff", "attack": "Spell_Simple_Shoot"},
}

const WOOD := Color("7a5236")
const STEEL := Color("aab2b8")
## The pictures of the nature models, by the name of their material.
const NATURE := {
	"NormalTree_Bark": "NormalTree_Bark", "NormalTree_Leaves": "NormalTree_Leaves", "PineTree_Bark": "PineTree_Bark",
	"PineTree_Leaves": "PineTree_Leaves", "BirchTree_Bark": "BirchTree_Bark", "BirchTree_Leaves": "BirchTree_Leaves",
	"Bush_Leaves": "Bush_Leaves", "Flowers": "Flowers", "Grass": "Grass", "Rock": "Rocks",
}

static var _animations: AnimationLibrary
static var _heads := {}
static var _painted := {}


## The animations every character shares.
static func animations() -> AnimationLibrary:
	if _animations == null:
		var source: Node = (load(DIR + "animations/UAL1.glb") as PackedScene).instantiate()
		_animations = (source.find_child("AnimationPlayer", true, false) as AnimationPlayer).get_animation_library("")
		_animations.get_animation("Sword_Idle").loop_mode = Animation.LOOP_LINEAR
		source.free()
	return _animations


static func character(id: String) -> Node3D:
	var info: Dictionary = CHARACTERS[id]
	var node: Node3D = (load(DIR + "characters/%s.gltf" % info.outfit) as PackedScene).instantiate()
	var skeleton: Skeleton3D = node.find_child("Skeleton3D", true, false)
	for part in info.get("hide", []):
		var found := node.find_child(part, true, false)
		if found:
			found.visible = false
	var female: bool = String(info.outfit).begins_with("Female")
	if info.get("head", false):
		for part in _head(female):
			var piece := MeshInstance3D.new()
			piece.name = part.name
			piece.mesh = part.mesh
			piece.skin = part.skin
			if part.has("tint"):
				_tint_surface(piece, 0, part.tint)
			_attach(skeleton, piece)
	if info.has("hair"):
		var hair: MeshInstance3D = _borrow("hair/%s.gltf" % info.hair, [])[0]
		_tint_surface(hair, 0, info.hair_color)
		_attach(skeleton, hair)
	for piece in _borrow("characters/Male_Ranger.gltf", info.get("armor", ["-"])):
		_attach(skeleton, piece)
	for mesh: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var original := mesh.mesh.surface_get_material(surface)
			if original == null:
				continue
			var kind := String(original.resource_name)
			if kind.begins_with("MI_Regular") or kind.begins_with("MI_Superhero"):
				if info.has("skin"):
					_tint_surface(mesh, surface, info.skin)
			elif kind in ["MI_Peasant", "MI_Ranger"] and info.has("cloth"):
				_tint_surface(mesh, surface, info.cloth)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	node.add_child(player)
	player.add_animation_library("", animations())
	return node


## Meshes taken out of another model of the same skeleton (hair, armour pieces).
static func _borrow(file: String, names: Array) -> Array:
	if names == ["-"]:
		return []
	var source: Node = (load(DIR + file) as PackedScene).instantiate()
	var meshes := []
	for mesh: MeshInstance3D in source.find_children("*", "MeshInstance3D", true, false):
		if names.is_empty() or mesh.name in names:
			mesh.owner = null
			mesh.get_parent().remove_child(mesh)
			meshes.append(mesh)
	source.free()
	return meshes


static func _attach(skeleton: Skeleton3D, mesh: MeshInstance3D) -> void:
	skeleton.add_child(mesh)
	mesh.skeleton = NodePath("..")


## Multiplies the colours of one surface, with a copy of its material kept for reuse.
static func _tint_surface(mesh: MeshInstance3D, surface: int, color: Color) -> void:
	var original := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
	if original == null:
		return
	var key := "%d %s" % [original.get_instance_id(), color.to_html()]
	if not _painted.has(key):
		var copy: StandardMaterial3D = original.duplicate()
		copy.albedo_color = color
		_painted[key] = copy
	mesh.set_surface_override_material(surface, _painted[key])


## The head, eyes and eyebrows of the base character, as {name, mesh, skin, tint}.
## Its body is one piece: the head is cut out of it (the triangles that follow the head and neck bones).
static func _head(female: bool) -> Array:
	if not _heads.has(female):
		var pieces := []
		var source: Node = (load(DIR + "base/Superhero_%s_FullBody.gltf" % ("Female" if female else "Male")) as PackedScene).instantiate()
		for mesh: MeshInstance3D in source.find_children("*", "MeshInstance3D", true, false):
			var part := {"name": "Head_" + mesh.name, "mesh": mesh.mesh, "skin": mesh.skin}
			var kind := String(mesh.mesh.surface_get_material(0).resource_name)
			if kind.begins_with("MI_Superhero"):
				part.mesh = _head_only(mesh)
			elif kind.begins_with("MI_Hair"):
				# Eyebrows: dark, whatever the hair.
				part["tint"] = Color("2a1c14")
			pieces.append(part)
		source.free()
		_heads[female] = pieces
	return _heads[female]


static func _head_only(mesh: MeshInstance3D) -> ArrayMesh:
	var keep := {}
	for bind in mesh.skin.get_bind_count():
		if String(mesh.skin.get_bind_name(bind)) in ["Head", "neck_01"]:
			keep[bind] = true
	var arrays := mesh.mesh.surface_get_arrays(0)
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var per_vertex := bones.size() / (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var kept := PackedInt32Array()
	for triangle in range(0, indices.size(), 3):
		var inside := 0
		for corner in 3:
			var vertex := indices[triangle + corner]
			var share := 0.0
			for slot in per_vertex:
				if keep.has(bones[vertex * per_vertex + slot]):
					share += weights[vertex * per_vertex + slot]
			if share > 0.5:
				inside += 1
		if inside == 3:
			kept.append_array([indices[triangle], indices[triangle + 1], indices[triangle + 2]])
	arrays[Mesh.ARRAY_INDEX] = kept
	var head := ArrayMesh.new()
	head.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, mesh.mesh.surface_get_format(0))
	head.surface_set_material(0, mesh.mesh.surface_get_material(0))
	return head


## Any model of assets/quaternius; the nature models get their pictures here.
static func model(file: String) -> Node3D:
	var node: Node3D = (load(DIR + file) as PackedScene).instantiate()
	if file.begins_with("nature/"):
		for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
			for surface in mesh.mesh.get_surface_count():
				var kind := String(mesh.mesh.surface_get_material(surface).resource_name)
				if NATURE.has(kind):
					mesh.set_surface_override_material(surface, _nature(NATURE[kind]))
	return node


static func _nature(picture: String, color := Color.WHITE) -> StandardMaterial3D:
	var key := "nature %s %s" % [picture, color.to_html()]
	if not _painted.has(key):
		var paint := StandardMaterial3D.new()
		paint.albedo_texture = load(DIR + "nature/%s.png" % picture)
		paint.albedo_color = color
		paint.roughness = 1.0
		if ResourceLoader.exists(DIR + "nature/%s_Normal.png" % picture):
			paint.normal_enabled = true
			paint.normal_texture = load(DIR + "nature/%s_Normal.png" % picture)
		if picture.ends_with("Leaves") or picture in ["Flowers", "Grass"]:
			paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			paint.alpha_scissor_threshold = 0.4
			paint.cull_mode = BaseMaterial3D.CULL_DISABLED
		_painted[key] = paint
	return _painted[key]


## A weapon to put in a hand or on the anvil. With a material, its metal takes
## the material's colours and the rarity's glow.
static func weapon(key: String, material := "", rarity := 0) -> Node3D:
	var info: Dictionary = WEAPONS[key]
	var node: Node3D
	if info.has("file"):
		node = model(info.file)
		node.scale *= float(info.get("grow", 1.0))
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
		for surface in mesh.mesh.get_surface_count():
			var original := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
			if original == null:
				continue
			var shader := ShaderMaterial.new()
			shader.shader = METAL
			shader.set_shader_parameter("albedo", original.albedo_texture)
			shader.set_shader_parameter("base", original.albedo_color)
			if original.metallic_texture:
				shader.set_shader_parameter("metal_map", original.metallic_texture)
				shader.set_shader_parameter("use_map", true)
			if original.normal_texture:
				shader.set_shader_parameter("normal_map", original.normal_texture)
				shader.set_shader_parameter("use_normal", true)
			var mat: Dictionary = Catalog.MATERIALS[material]
			shader.set_shader_parameter("metal_dark", mat.dark)
			shader.set_shader_parameter("metal_light", mat.light)
			if rarity > 0:
				shader.set_shader_parameter("glow", Catalog.RARITIES[rarity].color)
				shader.set_shader_parameter("glow_power", 0.35 + rarity * 0.2)
			mesh.set_surface_override_material(surface, shader)


## Frees a model. Its materials are taken off first: freed with the meshes that
## use them, they leave an error in the log.
static func discard(node: Node) -> void:
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.get_surface_override_material_count():
			mesh.set_surface_override_material(surface, null)
	node.queue_free()


## Sets the heat (0 to 1) of everything dressed under a node.
static func set_heat(node: Node, heat: float) -> void:
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.get_surface_override_material_count():
			var shader := mesh.get_surface_override_material(surface) as ShaderMaterial
			if shader:
				shader.set_shader_parameter("heat", heat)


# --- Shapes the packs do not have, made of simple blocks ---------------------
# Like the pack's weapons: the handle is at the origin, the head points up.

static func _build(shape: String) -> Node3D:
	var node := Node3D.new()
	match shape:
		"spear":
			_part(node, _rod(0.022, 1.6), WOOD, Vector3(0, 0.35, 0))
			_part(node, _spike(0.07, 0.34), STEEL, Vector3(0, 1.3, 0), Vector3.ZERO, Vector3(1, 1, 0.35))
			_part(node, _rod(0.04, 0.06), STEEL, Vector3(0, 1.12, 0))
		"scythe":
			_part(node, _rod(0.024, 1.8), WOOD, Vector3(0, 0.5, 0))
			_part(node, _spike(0.17, 0.75), STEEL, Vector3(0.34, 1.3, 0), Vector3(0, 0, -98), Vector3(1, 1, 0.12))
			_part(node, _rod(0.045, 0.08), STEEL, Vector3(0, 1.34, 0))
		"staff":
			_part(node, _rod(0.024, 1.4), Color("3a2a3a"), Vector3(0, 0.3, 0))
			_part(node, _ball(0.09), Color("b04ae0"), Vector3(0, 1.08, 0))
			_part(node, _spike(0.07, 0.14), STEEL, Vector3(0, 0.96, 0), Vector3(180, 0, 0))
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
