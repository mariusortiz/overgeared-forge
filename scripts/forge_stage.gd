extends Node2D
## The workshop drawn above the forge controls: furnace, anvil, water barrel, Grid.

const WIDTH := 360.0
const HEIGHT := 250.0
const FLOOR_Y := 172.0
const FURNACE := Vector2(66, 128)
const ANVIL := Vector2(170, 196)
const BARREL := Vector2(318, 196)
const WEAPON_ZOOM := 3.0

var heat := 0.0: set = set_heat

var _weapon: Sprite2D
var _weapon_glow: Sprite2D
var _furnace_glow: Sprite2D
var _hero: Sprite2D
var _hammer: Sprite2D
var _time := 0.0
var _shake := 0.0


func _ready() -> void:
	_furnace_glow = _glow(Color(1.0, 0.5, 0.15, 0.55), 190.0)
	_furnace_glow.position = FURNACE + Vector2(0, 10)
	add_child(_furnace_glow)

	var embers := CPUParticles2D.new()
	embers.position = FURNACE + Vector2(0, 18)
	embers.amount = 18
	embers.lifetime = 1.4
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(22, 4)
	embers.direction = Vector2(0, -1)
	embers.spread = 25.0
	embers.gravity = Vector2(0, -30)
	embers.initial_velocity_min = 20.0
	embers.initial_velocity_max = 55.0
	embers.scale_amount_min = 2.0
	embers.scale_amount_max = 3.0
	embers.color = Color(1.0, 0.7, 0.25)
	add_child(embers)

	var anvil := UI.tile_sprite(74, 5.0)
	anvil.position = ANVIL
	add_child(anvil)
	var barrel := UI.tile_sprite(82, 4.0)
	barrel.position = BARREL
	add_child(barrel)

	_hero = UI.tile_sprite(Catalog.HERO_TILE, 5.0)
	_hero.position = Vector2(246, 184)
	_hero.flip_h = true
	add_child(_hero)
	_hammer = UI.tile_sprite(117, 3.0)
	_hammer.position = Vector2(214, 170)
	_hammer.offset = Vector2(0, -6)
	_hammer.rotation = -0.5
	add_child(_hammer)

	_weapon_glow = _glow(Color(1.0, 0.6, 0.2, 0.0), 150.0)
	add_child(_weapon_glow)
	_weapon = Sprite2D.new()
	_weapon.scale = Vector2(WEAPON_ZOOM, WEAPON_ZOOM)
	_weapon.visible = false
	add_child(_weapon)


func _process(delta: float) -> void:
	_time += delta
	var flicker := 0.9 + 0.1 * sin(_time * 9.0) * sin(_time * 5.3)
	_furnace_glow.scale = Vector2.ONE * flicker * (1.0 + heat * 0.35)
	_weapon_glow.position = _weapon.position
	_shake = maxf(0.0, _shake - delta * 30.0)
	position = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	queue_redraw()


func _draw() -> void:
	# Wall and floor, from the dungeon tiles, darkened.
	var wall := UI.tile_texture(40)
	var ground := UI.tile_texture(48)
	for column in 8:
		for row in 4:
			draw_texture_rect(wall, Rect2(column * 48.0, row * 48.0 - 20.0, 48, 48), false, Color(0.42, 0.38, 0.55))
		for row in 2:
			draw_texture_rect(ground, Rect2(column * 48.0, FLOOR_Y + row * 48.0, 48, 48), false, Color(0.5, 0.4, 0.42))
	draw_rect(Rect2(0, FLOOR_Y - 4, WIDTH, 4), Color(0.1, 0.08, 0.14))
	draw_texture_rect(UI.tile_texture(29), Rect2(196, 30, 48, 48), false, Color(0.8, 0.75, 0.85))
	draw_texture_rect(UI.tile_texture(63), Rect2(280, 64, 48, 48), false, Color(0.7, 0.65, 0.75))
	draw_texture_rect(UI.tile_texture(75), Rect2(280, 112, 48, 48), false, Color(0.7, 0.65, 0.75))
	# The furnace: a stone block, its mouth and the fire inside.
	draw_rect(Rect2(14, 58, 104, 126), Color("2b2838"))
	draw_rect(Rect2(14, 58, 104, 126), Color("4b4368"), false, 4.0)
	draw_rect(Rect2(30, 18, 30, 40), Color("2b2838"))
	draw_rect(Rect2(34, 96, 64, 66), Color("120d12"))
	var fire := Color(1.0, 0.42, 0.1).lerp(Color(1.0, 0.85, 0.4), 0.5 + 0.5 * sin(_time * 7.0))
	for flame in 5:
		var tall := 22.0 + 14.0 * absf(sin(_time * (4.0 + flame) + flame * 1.7)) + heat * 16.0
		draw_rect(Rect2(38 + flame * 12.0, 160 - tall, 9, tall), fire.darkened(flame % 2 * 0.2))
	draw_rect(Rect2(34, 156, 64, 6), Color(1.0, 0.9, 0.6))


## Shows the bare blade of a plan, in the material's colours.
func show_weapon(plan: String, material: String, at: Vector2) -> void:
	_weapon.texture = UI.weapon_texture(plan)
	_weapon.material = UI.weapon_material(material, 0)
	_weapon.position = at
	_weapon.scale = Vector2(WEAPON_ZOOM, WEAPON_ZOOM)
	_weapon.visible = true
	heat = 0.0


func hide_weapon() -> void:
	_weapon.visible = false
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
	var tween := create_tween()
	tween.tween_property(_hammer, "rotation", -2.0, 0.06)
	tween.tween_property(_hammer, "rotation", -0.5, 0.2)
	_shake = 2.0 + accuracy * 4.0
	UI.sparks(self, _weapon.position, Color(1.0, 0.8, 0.3), 6 + int(accuracy * 18.0))
	var squash := create_tween()
	squash.tween_property(_weapon, "scale", Vector2(WEAPON_ZOOM * 1.12, WEAPON_ZOOM * 0.9), 0.05)
	squash.tween_property(_weapon, "scale", Vector2(WEAPON_ZOOM, WEAPON_ZOOM), 0.12)


## The blade goes into the water: steam, and the heat drops.
func quench() -> void:
	var steam := CPUParticles2D.new()
	steam.position = BARREL + Vector2(0, -28)
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


## The finished weapon rises above the anvil with its rarity's outline and light.
func reveal(material: String, rarity: int) -> void:
	_weapon.material = UI.weapon_material(material, rarity)
	var color: Color = Catalog.RARITIES[rarity].color
	_weapon_glow.modulate = Color(color, 0.25 + rarity * 0.12)
	var tween := create_tween().set_parallel()
	tween.tween_property(_weapon, "position", Vector2(WIDTH / 2.0, 96), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_weapon, "scale", Vector2(4, 4), 0.4)
	UI.sparks(self, Vector2(WIDTH / 2.0, 96), color, 10 + rarity * 10)
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
