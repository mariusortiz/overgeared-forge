extends Node2D
## The workshop shown above the forge controls: furnace, anvil, water trough, Grid.
## The backdrop comes from tools/build_backdrops.py; everything is drawn twice as large.

const WIDTH := 360.0
const HEIGHT := 250.0
## Where the item being forged is shown at each step.
const FURNACE := Vector2(70, 132)
const ANVIL := Vector2(186, 150)
const BARREL := Vector2(320, 168)
const WEAPON_ZOOM := 3.0
## The furnace picture: frame 0 cold, frames 1 to 3 burning.
const FIRE_FRAME := Vector2(64, 128)
const FIRE_AT := Vector2(4, -56)

var heat := 0.0: set = set_heat

var _weapon: Sprite2D
var _weapon_glow: Sprite2D
var _furnace_glow: Sprite2D
var _fire: Sprite2D
var _fire_atlas: AtlasTexture
var _hero: Actor
var _trophies: Node2D
var _time := 0.0
var _shake := 0.0


func _ready() -> void:
	var backdrop := Sprite2D.new()
	backdrop.texture = load("res://assets/lpc/backdrops/forge.png")
	backdrop.centered = false
	backdrop.scale = Vector2(2, 2)
	add_child(backdrop)

	_fire_atlas = AtlasTexture.new()
	_fire_atlas.atlas = load("res://assets/lpc/backdrops/forge_fire.png")
	_fire = Sprite2D.new()
	_fire.texture = _fire_atlas
	_fire.centered = false
	_fire.scale = Vector2(2, 2)
	_fire.position = FIRE_AT
	add_child(_fire)

	_furnace_glow = _glow(Color(1.0, 0.5, 0.15, 0.5), 200.0)
	_furnace_glow.position = FURNACE + Vector2(-2, 8)
	add_child(_furnace_glow)

	var embers := CPUParticles2D.new()
	embers.position = FURNACE + Vector2(-2, 6)
	embers.amount = 14
	embers.lifetime = 1.4
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(18, 4)
	embers.direction = Vector2(0, -1)
	embers.spread = 25.0
	embers.gravity = Vector2(0, -30)
	embers.initial_velocity_min = 20.0
	embers.initial_velocity_max = 55.0
	embers.scale_amount_min = 2.0
	embers.scale_amount_max = 2.0
	embers.color = Color(1.0, 0.7, 0.25)
	add_child(embers)

	_trophies = Node2D.new()
	add_child(_trophies)
	_dress()
	Save.changed.connect(_dress)

	_weapon_glow = _glow(Color(1.0, 0.6, 0.2, 0.0), 150.0)
	add_child(_weapon_glow)
	_weapon = Sprite2D.new()
	_weapon.scale = Vector2(WEAPON_ZOOM, WEAPON_ZOOM)
	_weapon.visible = false
	add_child(_weapon)


## Grid in the armour he has equipped, and his equipped weapons hung on the wall
## behind him. Called again each time the save changes.
func _dress() -> void:
	if _hero:
		_hero.queue_free()
	_hero = Actor.make_hero(true, 2.0)
	_hero.position = Vector2(262, 172)
	_hero.hold(UI.picture("hammer1"), UI.weapon_material("iron", 0))
	add_child(_hero)
	move_child(_hero, _trophies.get_index() + 1)
	for child in _trophies.get_children():
		child.queue_free()
	var weapons := Save.equipped_items("weapon")
	for index in weapons.size():
		var trophy := Sprite2D.new()
		trophy.texture = UI.weapon_texture(weapons[index].plan)
		trophy.material = UI.weapon_material(weapons[index].material, weapons[index].rarity)
		trophy.scale = Vector2(2, 2)
		trophy.position = Vector2(170 + index * 62, 36)
		_trophies.add_child(trophy)


func _process(delta: float) -> void:
	_time += delta
	_fire_atlas.region = Rect2((1 + int(_time * 7.0) % 3) * FIRE_FRAME.x, 0, FIRE_FRAME.x, FIRE_FRAME.y)
	var flicker := 0.9 + 0.1 * sin(_time * 9.0) * sin(_time * 5.3)
	_furnace_glow.scale = Vector2.ONE * flicker * (1.0 + heat * 0.35) * 200.0 / 64.0
	_weapon_glow.position = _weapon.position
	_shake = maxf(0.0, _shake - delta * 30.0)
	position = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))


## Shows the bare item of a plan, in the material's colours.
func show_weapon(plan: String, material_id: String, at: Vector2) -> void:
	_weapon.texture = UI.weapon_texture(plan)
	_weapon.material = UI.weapon_material(material_id, 0)
	_weapon.position = at
	_weapon.scale = Vector2(WEAPON_ZOOM, WEAPON_ZOOM)
	_weapon.visible = true
	_weapon_glow.modulate = Color(1.0, 0.6, 0.2, 0.0)
	heat = 0.0


func hide_weapon() -> void:
	_weapon.visible = false
	_weapon_glow.modulate.a = 0.0
	heat = 0.0


func move_weapon(to: Vector2) -> void:
	create_tween().tween_property(_weapon, "position", to, 0.35).set_trans(Tween.TRANS_SINE)


func set_heat(value: float) -> void:
	heat = clampf(value, 0.0, 1.0)
	if _weapon and _weapon.material:
		(_weapon.material as ShaderMaterial).set_shader_parameter("heat", heat)
		_weapon_glow.modulate.a = heat * 0.6


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
	steam.position = BARREL + Vector2(0, 14)
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


## The finished item rises above the anvil with its rarity's outline and light.
func reveal(material_id: String, rarity: int) -> void:
	_weapon.material = UI.weapon_material(material_id, rarity)
	var color: Color = Catalog.RARITIES[rarity].color
	_weapon_glow.modulate = Color(color, 0.25 + rarity * 0.12)
	var tween := create_tween().set_parallel()
	tween.tween_property(_weapon, "position", Vector2(WIDTH / 2.0, 90), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_weapon, "scale", Vector2(4, 4), 0.4)
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
