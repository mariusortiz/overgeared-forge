class_name Actor
extends Node2D
## A character drawn from a sheet of assets/lpc (made by tools/build_lpc.py):
## it breathes, swings the weapon it holds, and falls. Grid also shows the armour
## he wears and the other weapons he carries.

const SIZE := 64
## Columns of the sheet: [first frame, number of frames].
const IDLE := [0, 2]
const SLASH := [2, 6]
const HURT := [8, 6]
## Where the hand is, from the middle of a frame, when facing right.
const HAND := Vector2(9, 9)
## Where a weapon picture is held (its handle), from its top left corner.
const GRIP := Vector2(5, 27)
const REST_ANGLE := -0.25

var facing_left := false

var _body: Sprite2D
var _atlas: AtlasTexture
var _weapon: Sprite2D
var _overlay_atlas: AtlasTexture
var _shield: Sprite2D
var _back: Node2D
var _animation := IDLE
var _time := 0.0
var _fallen := false


static func make(character: String, left: bool, zoom: float) -> Actor:
	var actor := Actor.new()
	actor.facing_left = left
	actor.scale = Vector2(zoom, zoom)
	actor._back = Node2D.new()
	actor.add_child(actor._back)
	actor._atlas = AtlasTexture.new()
	actor._atlas.atlas = load("res://assets/lpc/%s.png" % character)
	actor._body = Sprite2D.new()
	actor._body.texture = actor._atlas
	actor.add_child(actor._body)
	actor._weapon = Sprite2D.new()
	actor._weapon.centered = false
	actor._weapon.offset = -GRIP
	actor._weapon.position = Vector2(-HAND.x if left else HAND.x, HAND.y)
	actor._weapon.scale.x = -1.0 if left else 1.0
	actor._weapon.rotation = actor._angle(REST_ANGLE)
	actor.add_child(actor._weapon)
	actor._show_frame(0)
	return actor


## Grid as the save describes him: wearing the armour he has equipped.
static func make_hero(left: bool, zoom: float) -> Actor:
	var hero := make(Catalog.HERO_SPRITE, left, zoom)
	for armor in Save.equipped_protection():
		var shader := UI.weapon_material(armor.material, armor.rarity)
		var plan: Dictionary = Catalog.PLANS[armor.plan]
		if plan.has("worn"):
			hero.wear(plan.worn, shader)
		else:
			hero.raise_shield(UI.weapon_texture(armor.plan), shader)
	return hero


## Draws another sheet over the body (an armour), frame for frame.
func wear(sheet: String, shader: Material = null) -> void:
	_overlay_atlas = AtlasTexture.new()
	_overlay_atlas.atlas = load("res://assets/lpc/%s.png" % sheet)
	_overlay_atlas.region = _atlas.region
	var overlay := Sprite2D.new()
	overlay.texture = _overlay_atlas
	overlay.material = shader
	add_child(overlay)
	move_child(overlay, _body.get_index() + 1)


## Shows a small picture on the arm away from the weapon.
func raise_shield(texture: Texture2D, shader: Material = null) -> void:
	_shield = Sprite2D.new()
	_shield.texture = texture
	_shield.material = shader
	_shield.scale = Vector2(0.55, 0.55)
	_shield.position = Vector2(4 if facing_left else -4, 10)
	add_child(_shield)
	move_child(_shield, _weapon.get_index())


## Shows weapons carried on the back: a list of [texture, shader].
func carry(weapons: Array) -> void:
	for child in _back.get_children():
		child.queue_free()
	for index in weapons.size():
		var sprite := Sprite2D.new()
		sprite.texture = weapons[index][0]
		sprite.material = weapons[index][1]
		sprite.centered = false
		sprite.offset = -GRIP
		# Mirrored, so that the blade rises behind the shoulder.
		sprite.scale.x = 1.0 if facing_left else -1.0
		sprite.position = Vector2(2 if facing_left else -2, 14)
		sprite.rotation = _angle(0.15 + index * 0.5)
		_back.add_child(sprite)


## Puts a weapon in the character's hand (null to empty it).
func hold(texture: Texture2D, shader: Material = null) -> void:
	_weapon.texture = texture
	_weapon.material = shader


func attack() -> void:
	if _fallen:
		return
	_animation = SLASH
	_time = 0.0
	var swing := create_tween()
	swing.tween_property(_weapon, "rotation", _angle(-1.3), 0.12)
	swing.tween_property(_weapon, "rotation", _angle(1.5), 0.14)
	swing.tween_property(_weapon, "rotation", _angle(REST_ANGLE), 0.2)


func fall() -> void:
	_fallen = true
	_animation = HURT
	_time = 0.0
	_weapon.visible = false
	_back.visible = false
	if _shield:
		_shield.visible = false


func _process(delta: float) -> void:
	_time += delta
	if _animation == IDLE:
		_show_frame(IDLE[0] + int(_time / 0.6) % IDLE[1])
	else:
		var frame := int(_time / 0.07)
		if frame >= _animation[1]:
			if _fallen:
				frame = _animation[1] - 1
			else:
				_animation = IDLE
				_time = 0.0
				frame = 0
		_show_frame(_animation[0] + frame)


func _show_frame(column: int) -> void:
	_atlas.region = Rect2(column * SIZE, SIZE if facing_left else 0, SIZE, SIZE)
	if _overlay_atlas:
		_overlay_atlas.region = _atlas.region


## Angles are given for a character facing right, and mirrored otherwise.
func _angle(value: float) -> float:
	return -value if facing_left else value
