extends Node2D
## The workshop shown above the forge controls: furnace, anvil, water barrel, Grid.
## The scene is in 3D (see stage3d.gd); the forge screen places the item being
## forged with the 2D points below.

const WIDTH := 360.0
const HEIGHT := 250.0
## Where the item being forged is shown at each step.
const FURNACE := Vector2(70, 132)
const ANVIL := Vector2(186, 150)
const BARREL := Vector2(320, 168)
const WEAPON_ZOOM := 3.0
## The item floats this far above the ground point under it.
const DROP := Vector2(0, 32)
const HERO_AT := Vector2(238, 126)
const BRICK := Color("8f5240")
const IRON := Color("3d4049")

var heat := 0.0: set = set_heat

var _stage: Stage3D
## The 2D handle of the item: the forge screen moves and scales it.
var _weapon: Node2D
var _item: Node3D
var _upright := 0.0
var _weapon_glow: Sprite2D
var _furnace_glow: Sprite2D
var _fire: OmniLight3D
var _hero: Actor
var _trophies: Node3D
var _time := 0.0
var _shake := 0.0


func _ready() -> void:
	_stage = Stage3D.make(Vector2(WIDTH, HEIGHT), Vector3(0, 3.0, 8.4), 17.0, 30.0)
	add_child(_stage)
	Scenery.build(_stage, "forge")
	_build_furniture()

	_furnace_glow = _glow(Color(1.0, 0.5, 0.15, 0.35), 200.0)
	_furnace_glow.position = FURNACE + Vector2(26, 4)
	add_child(_furnace_glow)

	var embers := CPUParticles2D.new()
	embers.position = FURNACE + Vector2(26, 0)
	embers.amount = 14
	embers.lifetime = 1.4
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(14, 4)
	embers.direction = Vector2(0, -1)
	embers.spread = 25.0
	embers.gravity = Vector2(0, -30)
	embers.initial_velocity_min = 20.0
	embers.initial_velocity_max = 55.0
	embers.scale_amount_min = 2.0
	embers.scale_amount_max = 2.0
	embers.color = Color(1.0, 0.7, 0.25)
	add_child(embers)

	_trophies = Node3D.new()
	_stage.world.add_child(_trophies)
	_dress()
	Save.changed.connect(_dress)

	_weapon_glow = _glow(Color(1.0, 0.6, 0.2, 0.0), 150.0)
	add_child(_weapon_glow)
	_weapon = Node2D.new()
	_weapon.scale = Vector2(WEAPON_ZOOM, WEAPON_ZOOM)
	_weapon.visible = false
	add_child(_weapon)


## The furnace, the anvil and the barrel, each under the point where the item goes.
func _build_furniture() -> void:
	var furnace := Node3D.new()
	furnace.position = _stage.ground(FURNACE + Vector2(30, -14) + DROP) + Vector3(-0.1, 0, -0.7)
	furnace.scale = Vector3.ONE * 0.7
	_stage.world.add_child(furnace)
	Models._part(furnace, Models._block(Vector3(2.1, 1.7, 1.4)), BRICK, Vector3(0, 0.85, 0))
	Models._part(furnace, Models._block(Vector3(2.3, 0.2, 1.6)), BRICK.darkened(0.25), Vector3(0, 1.75, 0))
	Models._part(furnace, Models._block(Vector3(0.9, 2.6, 0.9)), BRICK.darkened(0.15), Vector3(0, 3.1, -0.1))
	Models._part(furnace, Models._block(Vector3(1.2, 0.75, 0.2)), Color("1b1210"), Vector3(0, 0.95, 0.62))
	var flames := Models._part(furnace, Models._block(Vector3(1.0, 0.4, 0.1)), Color(1.0, 0.55, 0.15), Vector3(0, 0.8, 0.7))
	var burning := flames.mesh.surface_get_material(0) as StandardMaterial3D
	burning.emission_enabled = true
	burning.emission = Color(1.0, 0.5, 0.1)
	burning.emission_energy_multiplier = 2.5
	_fire = OmniLight3D.new()
	_fire.position = Vector3(0, 1.0, 1.4)
	_fire.light_color = Color(1.0, 0.55, 0.2)
	_fire.omni_range = 6.0
	furnace.add_child(_fire)

	var anvil := Node3D.new()
	anvil.position = _stage.ground(ANVIL + Vector2(0, -34) + DROP)
	anvil.scale = Vector3.ONE * 0.75
	_stage.world.add_child(anvil)
	Models._part(anvil, Models._block(Vector3(0.9, 0.5, 0.9)), Color("6b4a35"), Vector3(0, 0.25, 0))
	Models._part(anvil, Models._block(Vector3(0.7, 0.14, 0.5)), IRON, Vector3(0, 0.57, 0))
	Models._part(anvil, Models._block(Vector3(0.36, 0.2, 0.32)), IRON, Vector3(0, 0.7, 0))
	Models._part(anvil, Models._block(Vector3(1.0, 0.2, 0.5)), IRON.lightened(0.15), Vector3(0, 0.84, 0))
	Models._part(anvil, Models._spike(0.14, 0.45), IRON.lightened(0.15), Vector3(-0.7, 0.84, 0), Vector3(0, 0, 90))

	var at := _stage.ground(BARREL + Vector2(0, -40) + DROP)
	var barrel := Models.model("modular_dungeon_1/Barrel.glb")
	barrel.position = at
	barrel.scale *= 0.9
	_stage.world.add_child(barrel)
	var water := Models._part(_stage.world, Models._rod(0.3, 0.04), Color("4aa3d8"), at + Vector3(0, 0.78, 0))
	(water.mesh as CylinderMesh).radial_segments = 12


## Grid in the armour he has equipped, and his equipped weapons hung on the wall
## behind him. Called again each time the save changes.
func _dress() -> void:
	if _hero:
		_hero.queue_free()
	_hero = Actor.make_hero(_stage, true, 2.0)
	_hero.position = HERO_AT
	_hero.hold("hammer", "iron", 0)
	add_child(_hero)
	for child in _trophies.get_children():
		Models.discard(child)
	var weapons := Save.equipped_items("weapon")
	for index in weapons.size():
		var trophy := Models.weapon(weapons[index].plan, weapons[index].material, weapons[index].rarity)
		trophy.position = _stage.at_depth(Vector2(176 + index * 40, 62), -2.35)
		trophy.rotation_degrees = Vector3(0, 0, 180)
		trophy.scale *= 0.9
		_trophies.add_child(trophy)


func _process(delta: float) -> void:
	_time += delta
	var flicker := 0.9 + 0.1 * sin(_time * 9.0) * sin(_time * 5.3)
	_fire.light_energy = 0.55 * flicker + heat * 0.5
	_furnace_glow.scale = Vector2.ONE * flicker * (1.0 + heat * 0.35) * 200.0 / 64.0
	_weapon_glow.position = _weapon.position
	if _item:
		var depth := _stage.ground(_weapon.position + DROP).z
		_item.position = _stage.at_depth(_weapon.position, depth)
		_item.scale = Vector3(_weapon.scale.x, _weapon.scale.y, _weapon.scale.x) / WEAPON_ZOOM
		# Lying on its side while it is worked, standing and turning once revealed.
		_item.rotation = Vector3(0, _time * 1.5 * _upright, deg_to_rad(-90.0) * (1.0 - _upright))
		_item.visible = _weapon.visible
	_shake = maxf(0.0, _shake - delta * 30.0)
	position = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))


## Shows the bare item of a plan, in the material's colours.
func show_weapon(plan: String, material_id: String, at: Vector2) -> void:
	_make_item(plan, material_id, 0)
	_upright = 0.0
	_weapon.position = at
	_weapon.scale = Vector2(WEAPON_ZOOM, WEAPON_ZOOM)
	_weapon.visible = true
	_weapon.set_meta("plan", plan)
	_weapon_glow.modulate = Color(1.0, 0.6, 0.2, 0.0)
	heat = 0.0


func _make_item(plan: String, material_id: String, rarity: int) -> void:
	if _item:
		Models.discard(_item)
	_item = Models.weapon(plan, material_id, rarity)
	_stage.world.add_child(_item)


func hide_weapon() -> void:
	_weapon.visible = false
	_weapon_glow.modulate.a = 0.0
	heat = 0.0


func move_weapon(to: Vector2) -> void:
	create_tween().tween_property(_weapon, "position", to, 0.35).set_trans(Tween.TRANS_SINE)


func set_heat(value: float) -> void:
	heat = clampf(value, 0.0, 1.0)
	if _item:
		Models.set_heat(_item, heat)
		_weapon_glow.modulate.a = heat * 0.45


## A hammer blow: the better the timing, the more sparks.
func strike(accuracy: float) -> void:
	_hero.attack()
	_shake = 2.0 + accuracy * 4.0
	UI.sparks(self, _weapon.position, Color(1.0, 0.8, 0.3), 6 + int(accuracy * 18.0))
	var squash := create_tween()
	squash.tween_property(_weapon, "scale", Vector2(WEAPON_ZOOM * 1.12, WEAPON_ZOOM * 0.9), 0.05)
	squash.tween_property(_weapon, "scale", Vector2(WEAPON_ZOOM, WEAPON_ZOOM), 0.12)


## The item goes into the water: steam, and the heat drops.
func quench() -> void:
	var steam := CPUParticles2D.new()
	steam.position = BARREL + Vector2(0, -24)
	steam.amount = 26
	steam.one_shot = true
	steam.explosiveness = 0.7
	steam.lifetime = 1.1
	steam.direction = Vector2(0, -1)
	steam.spread = 35.0
	steam.gravity = Vector2(0, -60)
	steam.initial_velocity_min = 30.0
	steam.initial_velocity_max = 90.0
	steam.scale_amount_min = 4.0
	steam.scale_amount_max = 8.0
	steam.color = Color(0.9, 0.95, 1.0, 0.6)
	steam.emitting = true
	add_child(steam)
	steam.finished.connect(steam.queue_free)
	create_tween().tween_property(self, "heat", 0.0, 0.5)


## The finished item rises above the anvil, standing, with its rarity's glow.
func reveal(material_id: String, rarity: int) -> void:
	_make_item(_weapon.get_meta("plan"), material_id, rarity)
	_hero.cheer()
	var color: Color = Catalog.RARITIES[rarity].color
	_weapon_glow.modulate = Color(color, 0.2 + rarity * 0.1)
	var tween := create_tween().set_parallel()
	tween.tween_property(_weapon, "position", Vector2(WIDTH / 2.0, 96), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_weapon, "scale", Vector2(4, 4), 0.4)
	tween.tween_property(self, "_upright", 1.0, 0.4)
	UI.sparks(self, Vector2(WIDTH / 2.0, 90), color, 10 + rarity * 10)
	_shake = float(rarity) * 1.5


func _glow(color: Color, size: float) -> Sprite2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * size / 64.0
	sprite.modulate = color
	var blend := CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = blend
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return sprite
