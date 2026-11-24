extends Node
## The player's progress, kept in user://save.json.

const PATH := "user://save.json"

signal changed

var materials := {}
## Every forged item, weapon or armour: {uid, plan, material, rarity, score, attack, hp}.
var items: Array = []
var equipped: Array = []
var plans: Array = []
var album := {}
## The deepest floor ever cleared in the mine.
var best_floor := 0
var next_uid := 1
## With --test on the command line, nothing is read from or written to the disk.
var volatile := false
## About the last forged item: first of its kind, or its kind's best rarity so far.
var last_is_new := false
var last_is_best := false


func _ready() -> void:
	volatile = "--test" in OS.get_cmdline_user_args()
	reset()
	if not volatile:
		_load()


func reset() -> void:
	materials = Catalog.START_MATERIALS.duplicate()
	items = []
	equipped = []
	plans = Catalog.START_PLANS.duplicate()
	album = {}
	best_floor = 0
	next_uid = 1


func material_count(id: String) -> int:
	return int(materials.get(id, 0))


func add_material(id: String, count: int) -> void:
	materials[id] = material_count(id) + count
	store()


func knows(plan: String) -> bool:
	return plan in plans


func learn(plan: String) -> void:
	if plan != "" and plan not in plans:
		plans.append(plan)
		store()


func add_item(plan: String, material: String, rarity: int, score: float) -> Dictionary:
	var value := Catalog.item_value(plan, material, rarity, score)
	var weapon: bool = Catalog.PLANS[plan].slot == "weapon"
	var item := {
		"uid": next_uid, "plan": plan, "material": material, "rarity": rarity, "score": roundi(score),
		"attack": value if weapon else 0, "hp": 0 if weapon else value,
	}
	next_uid += 1
	items.append(item)
	if can_equip(item):
		equipped.append(item.uid)
	var key := Catalog.album_key(plan, material)
	last_is_new = not album.has(key)
	last_is_best = rarity > int(album.get(key, -1))
	album[key] = maxi(rarity, int(album.get(key, -1)))
	store()
	return item


func capacity() -> int:
	return Catalog.inventory_size(best_floor)


func is_full() -> bool:
	return items.size() >= capacity()


func remove_item(uid: int) -> void:
	equipped.erase(uid)
	for item in items:
		if item.uid == uid:
			items.erase(item)
			break
	store()


func is_equipped(uid: int) -> bool:
	return uid in equipped


## True while the item's slot (three weapons, one armour) still has room.
func can_equip(item: Dictionary) -> bool:
	var slot: String = Catalog.PLANS[item.plan].slot
	return equipped_items(slot).size() < Catalog.SLOT_LIMITS[slot]


func toggle_equipped(item: Dictionary) -> void:
	if item.uid in equipped:
		equipped.erase(item.uid)
	elif can_equip(item):
		equipped.append(item.uid)
	store()


func equipped_items(slot: String) -> Array:
	var list := []
	for uid in equipped:
		for item in items:
			if item.uid == uid and Catalog.PLANS[item.plan].slot == slot:
				list.append(item)
	return list


## The floors the player may start from: the first, and the one after each boss beaten.
func start_floors() -> Array:
	var list := [1]
	var level := Catalog.BOSS_EVERY
	while level <= best_floor:
		list.append(level + 1)
		level += Catalog.BOSS_EVERY
	return list


func store() -> void:
	changed.emit()
	if volatile:
		return
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"materials": materials, "items": items, "equipped": equipped, "plans": plans,
		"album": album, "best_floor": best_floor, "next_uid": next_uid,
	}))


func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return
	# JSON only knows floats: numbers are turned back into integers.
	for id in data.get("materials", {}):
		if Catalog.MATERIALS.has(id):
			materials[id] = int(data.materials[id])
	# "weapons" is the name the first version gave to the list.
	for saved in data.get("items", data.get("weapons", [])):
		if Catalog.PLANS.has(saved.get("plan")) and Catalog.MATERIALS.has(saved.get("material")):
			items.append({
				"uid": int(saved.uid), "plan": saved.plan, "material": saved.material,
				"rarity": int(saved.rarity), "score": int(saved.score),
				"attack": int(saved.get("attack", 0)), "hp": int(saved.get("hp", 0)),
			})
			learn(saved.plan)
	for uid in data.get("equipped", []):
		equipped.append(int(uid))
	for plan in data.get("plans", []):
		if Catalog.PLANS.has(plan) and plan not in plans:
			plans.append(plan)
	for key in data.get("album", {}):
		album[key] = int(data.album[key])
	best_floor = int(data.get("best_floor", 0))
	next_uid = int(data.get("next_uid", 1))
