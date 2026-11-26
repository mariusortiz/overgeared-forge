class_name Actor
extends Node2D
## A character of the game. The 2D code moves this node on the picture of a
## Stage3D; its 3D model (see data/models.gd) follows on the ground of the scene,
## breathes, swings the weapon it holds, and falls. Grid also shows the armour
## he wears and the other weapons he carries.

## From this node down to the ground under the character's feet.
const FEET := Vector2(0, 52)
## Characters are turned a little towards the player.
const TURN := deg_to_rad(62.0)

var facing_left := false
var model: Node3D

var _stage: Stage3D
var _player: AnimationPlayer
var _skeleton: Skeleton3D
var _hands := {}
var _size := 1.0
var _attack := "Unarmed_Melee_Attack_Punch_A"
var _idle := "Idle"
var _fallen := false


static func make(stage: Stage3D, character: String, left: bool, zoom: float) -> Actor:
	var actor := Actor.new()
	var info: Dictionary = Models.CHARACTERS[character]
	actor._stage = stage
	actor.facing_left = left
	actor._size = float(info.get("size", 1.0)) * zoom / 2.0
	actor.model = Models.character(character)
	actor.model.rotation.y = -TURN if left else TURN
	actor.model.scale = Vector3.ONE * actor._size
	stage.world.add_child(actor.model)
	actor._player = actor.model.find_child("AnimationPlayer", true, false)
	actor._skeleton = actor.model.find_child("Skeleton3D", true, false)
	for name in ["Idle", "2H_Melee_Idle"]:
		actor._player.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	actor._player.play("Idle")
	# Not everybody breathes in step.
	actor._player.seek(randf() * 1.0)
	if info.has("weapon"):
		actor.hold(info.weapon)
	return actor


## Grid as the save describes him: in the armour and with the shield he has equipped.
static func make_hero(stage: Stage3D, left: bool, zoom: float) -> Actor:
	var armors := Save.equipped_items("armor")
	var hero := make(stage, "grid" if armors.is_empty() else "grid_armor", left, zoom)
	if not armors.is_empty():
		Models.dress(hero.model, armors[0].material, armors[0].rarity,
			["Knight_Body", "Knight_ArmLeft", "Knight_ArmRight", "Knight_LegLeft", "Knight_LegRight"])
	for shield in Save.equipped_items("shield"):
		hero._put("handslot.l", [Models.weapon("shield", shield.material, shield.rarity)])
	return hero


## Puts a weapon in the character's hand: a key of Models.WEAPONS.
func hold(weapon: String, material := "", rarity := 0) -> void:
	var info: Dictionary = Models.WEAPONS[weapon]
	_attack = info.attack
	_idle = info.get("idle", "Idle")
	_put("handslot.r", [Models.weapon(weapon, material, rarity)])
	if not _fallen and _player.current_animation in ["Idle", "2H_Melee_Idle"]:
		_player.play(_idle, 0.2)


## Shows the other weapons on the back: a list of items of the save.
func carry(items: Array) -> void:
	var nodes := []
	for index in items.size():
		var weapon := Models.weapon(items[index].plan, items[index].material, items[index].rarity)
		weapon.position = Vector3(0.12 - index * 0.24, -0.35, -0.32)
		weapon.rotation_degrees = Vector3(0, 90, 160 + index * 40)
		weapon.scale = Vector3.ONE * 0.85
		nodes.append(weapon)
	_put("chest", nodes)


func attack() -> void:
	_play(_attack)


func hurt() -> void:
	_play("Hit_A")


func block() -> void:
	_play("Block_Hit")


func cheer() -> void:
	_play("Cheer")


func fall() -> void:
	if _fallen:
		return
	_fallen = true
	_player.play("Death_A", 0.1)


func _play(animation: String) -> void:
	if _fallen:
		return
	_player.play(animation, 0.12)
	_player.queue(_idle)


## Replaces what is attached to a bone of the skeleton.
func _put(bone: String, nodes: Array) -> void:
	if not _hands.has(bone):
		var hand := BoneAttachment3D.new()
		hand.bone_name = bone
		_skeleton.add_child(hand)
		_hands[bone] = hand
	for child in _hands[bone].get_children():
		Models.discard(child)
	for node in nodes:
		_hands[bone].add_child(node)


func _process(_delta: float) -> void:
	model.position = _stage.ground(_stage.to_local(global_position) + FEET)
	model.visible = is_visible_in_tree()
	# The 2D node's scale still counts: it lets the 2D code make a character pop in.
	model.scale = Vector3.ONE * _size * scale.x


func _exit_tree() -> void:
	if is_instance_valid(model):
		Models.discard(model)
