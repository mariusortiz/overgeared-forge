class_name Actor
extends Node2D
## A character of the game. The 2D code moves this node on the picture of a
## Stage3D; its 3D model (see data/models.gd) follows on the ground of the scene,
## breathes, swings the weapon it holds, and falls. Grid also shows the armour
## he wears and the other weapons he carries.

## From this node down to the ground under the character's feet.
const FEET := Vector2(0, 52)
## Characters are turned a little towards the player.
const TURN := deg_to_rad(58.0)
## How a weapon sits in a closed hand.
const GRIP_TURN := Vector3(90, 0, 0)
const GRIP_AT := Vector3(0, 0.09, 0.03)

var facing_left := false
var model: Node3D

var _stage: Stage3D
var _player: AnimationPlayer
var _skeleton: Skeleton3D
var _hands := {}
var _size := 1.0
var _attack := "Punch_Cross"
var _idle := "Sword_Idle"
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
	actor._player.play("Sword_Idle")
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
		Models.dress(hero.model, armors[0].material, armors[0].rarity, Models.CHARACTERS.grid_armor.armor)
	for shield in Save.equipped_items("shield"):
		var worn := Models.weapon("shield", shield.material, shield.rarity)
		worn.rotation_degrees = Vector3(0, 90, 90)
		worn.position = Vector3(-0.06, 0.02, 0)
		hero._put("lowerarm_l", [worn])
	return hero


## Puts a weapon in the character's hand: a key of Models.WEAPONS.
func hold(weapon: String, material := "", rarity := 0) -> void:
	var info: Dictionary = Models.WEAPONS[weapon]
	_attack = info.attack
	var held := Models.weapon(weapon, material, rarity)
	held.rotation_degrees = GRIP_TURN
	held.position = GRIP_AT
	_put("hand_r", [held])


## Shows the other weapons on the back: a list of items of the save.
func carry(items: Array) -> void:
	var nodes := []
	for index in items.size():
		var weapon := Models.weapon(items[index].plan, items[index].material, items[index].rarity)
		weapon.position = Vector3(0.1 - index * 0.2, -0.25, -0.16)
		weapon.rotation_degrees = Vector3(0, 90, 160 + index * 40)
		weapon.scale *= 0.85
		nodes.append(weapon)
	_put("spine_03", nodes)


func attack() -> void:
	_play(_attack)


func hurt() -> void:
	_play("Hit_Chest")


func block() -> void:
	_play("Hit_Head")


func cheer() -> void:
	_play("Interact")


func fall() -> void:
	if _fallen:
		return
	_fallen = true
	_player.play("Death01", 0.1)


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
