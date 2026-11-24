extends Node
## The player's progress, kept in user://save.json.

const PATH := "user://save.json"

signal changed

var materials := {}
var weapons: Array = []
var equipped: Array = []
var album := {}
var mine_level := 1
var next_uid := 1
## With --test on the command line, nothing is read from or written to the disk.
var volatile := false
## About the last forged weapon: first of its kind, or its kind's best rarity so far.
var last_is_new := false
var last_is_best := false


func _ready() -> void:
	volatile = "--test" in OS.get_cmdline_user_args()
	reset()
	if not volatile:
		_load()


func reset() -> void:
	materials = Catalog.START_MATERIALS.duplicate()
	weapons = []
	equipped = []
	album = {}
	mine_level = 1
	next_uid = 1


func material_count(id: String) -> int:
	return int(materials.get(id, 0))


func add_material(id: String, count: int) -> void:
	materials[id] = material_count(id) + count
	store()


func add_weapon(plan: String, material: String, rarity: int, score: float) -> Dictionary:
	var weapon := {
		"uid": next_uid, "plan": plan, "material": material, "rarity": rarity,
		"score": roundi(score), "attack": Catalog.weapon_attack(plan, material, rarity, score),
	}
	next_uid += 1
	weapons.append(weapon)
	if equipped.size() < Catalog.MAX_EQUIPPED:
		equipped.append(weapon.uid)
	var key := Catalog.album_key(plan, material)
	last_is_new = not album.has(key)
	last_is_best = rarity > int(album.get(key, -1))
	album[key] = maxi(rarity, int(album.get(key, -1)))
	store()
	return weapon


func remove_weapon(uid: int) -> void:
	equipped.erase(uid)
	for weapon in weapons:
		if weapon.uid == uid:
			weapons.erase(weapon)
			break
	store()


func is_equipped(uid: int) -> bool:
	return uid in equipped


func toggle_equipped(uid: int) -> void:
	if uid in equipped:
		equipped.erase(uid)
	elif equipped.size() < Catalog.MAX_EQUIPPED:
		equipped.append(uid)
	store()


func equipped_weapons() -> Array:
	var list := []
	for uid in equipped:
		for weapon in weapons:
			if weapon.uid == uid:
				list.append(weapon)
	return list


func store() -> void:
	changed.emit()
	if volatile:
		return
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"materials": materials, "weapons": weapons, "equipped": equipped,
		"album": album, "mine_level": mine_level, "next_uid": next_uid,
	}))


func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return
	# JSON only knows floats: numbers are turned back into integers.
	for id in data.get("materials", {}):
		materials[id] = int(data.materials[id])
	for saved in data.get("weapons", []):
		if Catalog.PLANS.has(saved.get("plan")) and Catalog.MATERIALS.has(saved.get("material")):
			weapons.append({
				"uid": int(saved.uid), "plan": saved.plan, "material": saved.material,
				"rarity": int(saved.rarity), "score": int(saved.score), "attack": int(saved.attack),
			})
	for uid in data.get("equipped", []):
		equipped.append(int(uid))
	for key in data.get("album", {}):
		album[key] = int(data.album[key])
	mine_level = int(data.get("mine_level", 1))
	next_uid = int(data.get("next_uid", 1))
