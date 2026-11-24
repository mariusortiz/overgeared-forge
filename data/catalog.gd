class_name Catalog
## The game's content: rarities, materials, plans, enemies, loot.
## Change the numbers here to tune the game; nothing else needs to be touched.

const RARITIES := [
	{"name": "Normal", "color": Color("9aa0aa"), "mult": 1.0},
	{"name": "Rare", "color": Color("4a9df0"), "mult": 1.3},
	{"name": "Épique", "color": Color("b05cf0"), "mult": 1.7},
	{"name": "Unique", "color": Color("f0d040"), "mult": 2.2},
	{"name": "Légendaire", "color": Color("ff8a1e"), "mult": 3.0},
	{"name": "Mythique", "color": Color("ff3b5c"), "mult": 4.0},
]
const MYTH := 5

const ELEMENTS := {
	"none": {"name": "Neutre", "color": Color("b8bcc6")},
	"fire": {"name": "Feu", "color": Color("ff7a3c")},
	"ice": {"name": "Glace", "color": Color("7fd8ff")},
	"lightning": {"name": "Foudre", "color": Color("c9a2ff")},
}

## max_rarity: the best rarity this material can reach (index in RARITIES).
## better: the finer materials a high-rarity item of this one can give when melted.
## dark and light: the colours the metal of a weapon takes.
const MATERIALS := {
	"iron": {"better": ["ember", "frost", "storm"], "name": "Fer", "short": "Fer", "element": "none", "power": 1.0, "max_rarity": 2,
		"dark": Color("55566a"), "light": Color("e7f0f4")},
	"ember": {"better": ["mithril"], "name": "Acier ardent", "short": "Ardent", "element": "fire", "power": 1.25, "max_rarity": 3,
		"dark": Color("6e2a1e"), "light": Color("ffc078")},
	"frost": {"better": ["mithril"], "name": "Givre-argent", "short": "Givre", "element": "ice", "power": 1.25, "max_rarity": 3,
		"dark": Color("2f5f86"), "light": Color("e2fbff")},
	"storm": {"better": ["mithril"], "name": "Pierre d'orage", "short": "Orage", "element": "lightning", "power": 1.25, "max_rarity": 3,
		"dark": Color("4a2a80"), "light": Color("e6ccff")},
	"mithril": {"better": ["orichalcum"], "name": "Mithril", "short": "Mithril", "element": "none", "power": 1.6, "max_rarity": 4,
		"dark": Color("2f6a62"), "light": Color("e6fff4")},
	"orichalcum": {"better": ["orichalcum"], "name": "Orichalque bleu", "short": "Orichalque", "element": "lightning", "power": 2.0, "max_rarity": 4,
		"dark": Color("2a2f9a"), "light": Color("9fd0ff")},
}
const MATERIAL_ORDER := ["iron", "ember", "frost", "storm", "mithril", "orichalcum"]
## Only this material can give a mythic item.
const MYTH_MATERIAL := "orichalcum"

## Weapons have an attack and a skill; armours have hit points and may block.
## worn: a sheet of assets/lpc drawn over Grid when he wears the armour; without
## it, the armour's picture is shown on his arm, like a shield.
## Skill kinds: "single" one enemy, "double" two hits, "all" every enemy,
## "stun" the enemy misses its next attack, "drain" half the damage heals Grid.
const PLANS := {
	"sword": {"name": "Épée", "slot": "weapon", "sprite": "sword5", "attack": 12,
		"skill": {"name": "Taillade", "kind": "single", "power": 2.0, "cooldown": 2}},
	"dagger": {"name": "Dague", "slot": "weapon", "sprite": "dagger3", "attack": 9,
		"skill": {"name": "Double frappe", "kind": "double", "power": 1.1, "cooldown": 2}},
	"spear": {"name": "Lance", "slot": "weapon", "sprite": "spear1", "attack": 10,
		"skill": {"name": "Percée", "kind": "all", "power": 0.9, "cooldown": 2}},
	"shield": {"name": "Bouclier", "slot": "armor", "sprite": "shield", "hp": 12, "block": 0.15},
	"axe": {"name": "Hache", "slot": "weapon", "sprite": "axe3", "attack": 14,
		"skill": {"name": "Fendoir", "kind": "single", "power": 3.0, "cooldown": 4}},
	"plate": {"name": "Plastron", "slot": "armor", "sprite": "plate", "hp": 25, "block": 0.0, "worn": "armor_plate"},
	"hammer": {"name": "Marteau", "slot": "weapon", "sprite": "hammer1", "attack": 13,
		"skill": {"name": "Choc", "kind": "stun", "power": 1.5, "cooldown": 3}},
	"scythe": {"name": "Faux", "slot": "weapon", "sprite": "scythe1", "attack": 12,
		"skill": {"name": "Moisson", "kind": "drain", "power": 1.8, "cooldown": 3}},
}
## The order of the forge and the album. The first START_PLANS are known from the
## start; each boss beaten in the mine gives the next one.
const PLAN_ORDER := ["sword", "dagger", "spear", "shield", "axe", "plate", "hammer", "scythe"]
const START_PLANS := ["sword", "dagger"]
const START_MATERIALS := {"iron": 6}

const FORGE_COST := 3
## To reach a rarity: [rarity, lowest note, lowest note allowed for the weakest gesture].
## One failed gesture is enough to miss the high rarities.
const RARITY_RULES := [[1, 55, 0], [2, 72, 50], [3, 84, 65], [4, 93, 80]]
## The note moves by this much, up or down, at random.
const RARITY_LUCK := 4.0
## Mythic: [lowest note, lowest note for the weakest gesture, chances].
const MYTH_RULE := [96, 90, 0.2]
const SLOT_LIMITS := {"weapon": 3, "armor": 1}

## How many items Grid can keep, equipped ones included: a base, plus one for
## each boss beaten, up to a maximum. Beyond that, something must be melted.
const INVENTORY_BASE := 8
const INVENTORY_PER_BOSS := 1
const INVENTORY_MAX := 14
## What melting an item gives back, by rarity: [units of its material, units of a
## better material]. Never more than the three units the forge took.
const MELT := [[1, 0], [1, 0], [2, 0], [1, 1], [1, 2], [1, 2]]

# --- Jewels ----------------------------------------------------------------

## Jewels are set into items. The jewels of everything Grid has equipped add up.
## effect: "attack" (% of attack), "hp" (hit points), "heal" (hit points given
## back for each enemy beaten). values: one for each grade.
const JEWELS := {
	"ruby": {"name": "Rubis", "color": Color("ff4d5e"), "effect": "attack", "values": [8, 15, 25], "text": "+%d %% d'attaque"},
	"sapphire": {"name": "Saphir", "color": Color("4d8dff"), "effect": "hp", "values": [10, 20, 35], "text": "+%d PV"},
	"emerald": {"name": "Émeraude", "color": Color("3ddc84"), "effect": "heal", "values": [3, 6, 10], "text": "+%d PV par ennemi battu"},
}
const JEWEL_ORDER := ["ruby", "sapphire", "emerald"]
const JEWEL_GRADES := ["C", "B", "S"]
## How many jewels an item can hold, by rarity.
const SOCKETS := [0, 1, 1, 2, 3, 3]
## A boss always drops a jewel; its grade is drawn with these weights [C, B, S],
## one line for each zone. Other enemies drop a grade C jewel now and then.
const BOSS_JEWELS := [[100, 0, 0], [60, 40, 0], [30, 50, 20], [0, 50, 50]]
const JEWEL_CHANCE := 0.04

const HERO_NAME := "Grid"
const HERO_SPRITE := "grid"
const HERO_HP := 120
## Without any weapon, Grid fights with his forge hammer.
const BARE_WEAPON := {"uid": 0, "plan": "hammer", "material": "iron", "rarity": 0, "attack": 6, "bare": true}
const WEAK_BONUS := 1.5

# --- The mine --------------------------------------------------------------

## Every floor is a fight; every BOSS_EVERY floors, a boss. Enemies get this
## much stronger at each floor.
const BOSS_EVERY := 5
const FLOOR_GROWTH := 1.1
## How many enemies on the floors before a boss.
const FLOOR_SIZES := [2, 2, 3, 3]

## sprite: a character of assets/lpc (see tools/build_lpc.py);
## weapon: a picture of assets/weapons, held in hand.
const ENEMIES := {
	"goblin": {"name": "Gobelin", "sprite": "goblin", "weapon": "mace2", "hp": 22, "attack": 3, "weak": "fire"},
	"skeleton": {"name": "Squelette", "sprite": "skeleton", "weapon": "sword1", "hp": 24, "attack": 4, "weak": "lightning"},
	"orc": {"name": "Orc", "sprite": "orc", "weapon": "axe1", "hp": 32, "attack": 5, "weak": "ice"},
	"soldier": {"name": "Soldat d'Ashur", "sprite": "soldier", "weapon": "spear2", "hp": 28, "attack": 5, "weak": "ice"},
	"mercenary": {"name": "Mercenaire", "sprite": "mercenary", "weapon": "dagger1", "hp": 26, "attack": 6, "weak": "fire"},
	"knight": {"name": "Chevalier d'Ashur", "sprite": "knight", "weapon": "sword3", "hp": 42, "attack": 5, "weak": "lightning"},
	"cultist": {"name": "Adepte de Yatan", "sprite": "cultist", "weapon": "dagger5", "hp": 30, "attack": 7, "weak": "ice"},
	"zealot": {"name": "Fanatique", "sprite": "zealot", "weapon": "mace1", "hp": 34, "attack": 8, "weak": "fire"},
	"dark_priest": {"name": "Prêtre noir", "sprite": "dark_priest", "weapon": "staff1", "hp": 28, "attack": 9, "weak": "lightning"},
	"rival": {"name": "Joueur rival", "sprite": "rival", "weapon": "sword1", "hp": 44, "attack": 8, "weak": "fire"},
	"orc_chief": {"name": "Chef orc", "sprite": "orc_chief", "weapon": "axe4", "hp": 160, "attack": 9, "weak": "fire", "boss": true},
	"captain": {"name": "Capitaine d'Ashur", "sprite": "captain", "weapon": "sword3", "hp": 170, "attack": 10, "weak": "lightning", "boss": true},
	"malacus": {"name": "Malacus", "sprite": "malacus", "weapon": "staff3", "hp": 180, "attack": 11, "weak": "ice", "boss": true},
}
## One zone for every BOSS_EVERY floors; the last one serves for all deeper floors.
## backdrop: a picture of assets/lpc/backdrops (see tools/build_backdrops.py).
const ZONES := [
	{"name": "Canyon de Kesan", "backdrop": "canyon", "enemies": ["goblin", "skeleton", "orc"]},
	{"name": "Terres du comte Ashur", "backdrop": "castle", "enemies": ["soldier", "mercenary", "knight"]},
	{"name": "Temple de Yatan", "backdrop": "temple", "enemies": ["cultist", "zealot", "dark_priest"]},
	{"name": "Profondeurs", "backdrop": "temple", "enemies": ["rival", "knight", "dark_priest", "orc"]},
]
const BOSSES := ["orc_chief", "captain", "malacus"]

## What an enemy drops, by depth: [material, weight]. One line for each zone.
## A boss drops BOSS_DROPS materials from the next line, and a new plan.
const LOOT := [
	[["iron", 70], ["ember", 10], ["frost", 10], ["storm", 10]],
	[["iron", 30], ["ember", 20], ["frost", 20], ["storm", 20], ["mithril", 10]],
	[["iron", 10], ["ember", 15], ["frost", 15], ["storm", 15], ["mithril", 35], ["orichalcum", 10]],
	[["ember", 10], ["frost", 10], ["storm", 10], ["mithril", 40], ["orichalcum", 30]],
]
const BOSS_DROPS := 4

## What the player picks after a floor, before going down.
const BONUSES := [
	{"id": "heal", "name": "Potion", "text": "Rend 35 % des points de vie"},
	{"id": "attack", "name": "Aiguisage", "text": "+15 % d'attaque"},
	{"id": "guard", "name": "Renfort", "text": "-10 % de dégâts reçus"},
]


## The rarity of a forged item, from the note (0 to 100) of the three gestures
## and the note of the weakest of them.
static func roll_rarity(score: float, weakest: float, material: String, rng: RandomNumberGenerator) -> int:
	var quality := score + rng.randf_range(-RARITY_LUCK, RARITY_LUCK)
	var rarity := 0
	for rule in RARITY_RULES:
		if quality >= rule[1] and weakest >= rule[2]:
			rarity = rule[0]
	var mat: Dictionary = MATERIALS[material]
	rarity = mini(rarity, mat.max_rarity)
	# A near-perfect forge with the best material can go beyond legendary.
	if material == MYTH_MATERIAL and score >= MYTH_RULE[0] and weakest >= MYTH_RULE[1] and rng.randf() < MYTH_RULE[2]:
		rarity = MYTH
	return rarity


## What it takes to get the rarity above this one, as a sentence; "" at the top.
static func next_rarity_hint(rarity: int, material: String) -> String:
	if rarity >= MATERIALS[material].max_rarity:
		return ""
	for rule in RARITY_RULES:
		if rule[0] == rarity + 1:
			var text := "%s : note %d" % [RARITIES[rule[0]].name, rule[1]]
			if rule[2] > 0:
				text += ", aucun geste sous %d" % rule[2]
			return text
	return ""


## An item's attack (weapon) or hit points (armour).
static func item_value(plan: String, material: String, rarity: int, score: float) -> int:
	var info: Dictionary = PLANS[plan]
	var base: float = info.attack if info.slot == "weapon" else info.hp
	return roundi(base * MATERIALS[material].power * RARITIES[rarity].mult * (0.9 + score / 500.0))


static func is_weapon(item: Dictionary) -> bool:
	return PLANS[item.plan].slot == "weapon"


static func item_name(item: Dictionary) -> String:
	if item.get("bare", false):
		return "Marteau de forge"
	return "%s · %s" % [PLANS[item.plan].name, MATERIALS[item.material].name]


## The line of numbers shown under an item's name.
static func item_stats(item: Dictionary) -> String:
	if is_weapon(item):
		return "Attaque %d · %s" % [item.attack, ELEMENTS[item_element(item)].name]
	var block: float = PLANS[item.plan].block
	return "PV +%d" % item.hp + (" · bloque %d %%" % roundi(block * 100) if block > 0.0 else "")


static func item_element(item: Dictionary) -> String:
	return MATERIALS[item.material].element


static func inventory_size(best_floor: int) -> int:
	@warning_ignore("integer_division")
	return mini(INVENTORY_BASE + best_floor / BOSS_EVERY * INVENTORY_PER_BOSS, INVENTORY_MAX)


## The materials melting an item gives: {material: units}.
static func melt_yield(item: Dictionary) -> Dictionary:
	var line: Array = MELT[item.rarity]
	var result := {item.material: line[0]}
	if line[1] > 0:
		var options: Array = MATERIALS[item.material].better
		var better: String = options[item.uid % options.size()]
		result[better] = int(result.get(better, 0)) + line[1]
	return result


## A list of materials as a sentence: "Fer 2, Mithril 1".
static func materials_text(amounts: Dictionary) -> String:
	var parts := []
	for id in MATERIAL_ORDER:
		if int(amounts.get(id, 0)) > 0:
			parts.append("%s %d" % [MATERIALS[id].short, amounts[id]])
	return "rien" if parts.is_empty() else ", ".join(parts)


static func album_key(plan: String, material: String) -> String:
	return plan + ":" + material


# --- Jewels' rules ----------------------------------------------------------

## A jewel is written "kind:grade", for example "ruby:1" for a grade B ruby.
static func jewel_id(kind: String, grade: int) -> String:
	return "%s:%d" % [kind, grade]


static func jewel_kind(id: String) -> Dictionary:
	return JEWELS[id.get_slice(":", 0)]


static func jewel_grade(id: String) -> int:
	return int(id.get_slice(":", 1))


static func jewel_name(id: String) -> String:
	return "%s %s" % [jewel_kind(id).name, JEWEL_GRADES[jewel_grade(id)]]


static func jewel_effect(id: String) -> String:
	var kind := jewel_kind(id)
	return kind.text % kind.values[jewel_grade(id)]


## Every jewel there is, in the order they are listed.
static func all_jewels() -> Array:
	var list := []
	for kind in JEWEL_ORDER:
		for grade in JEWEL_GRADES.size():
			list.append(jewel_id(kind, grade))
	return list


static func roll_jewel(tier: int, boss: bool, rng: RandomNumberGenerator) -> String:
	var grade := 0
	if boss:
		var weights: Array = BOSS_JEWELS[clampi(tier, 0, BOSS_JEWELS.size() - 1)]
		var pick: float = rng.randf() * (weights[0] + weights[1] + weights[2])
		grade = 0 if pick < weights[0] else (1 if pick < weights[0] + weights[1] else 2)
	return jewel_id(JEWEL_ORDER[rng.randi() % JEWEL_ORDER.size()], grade)


## What the jewels of a list of items add up to: {"attack": %, "hp": n, "heal": n}.
static func jewel_bonus(items: Array) -> Dictionary:
	var total := {"attack": 0, "hp": 0, "heal": 0}
	for item in items:
		for id in item.get("jewels", []):
			var kind := jewel_kind(id)
			total[kind.effect] += kind.values[jewel_grade(id)]
	return total


## A list of jewels as a sentence: "Rubis C 2, Saphir B 1".
static func jewels_text(amounts: Dictionary) -> String:
	var parts := []
	for id in all_jewels():
		if int(amounts.get(id, 0)) > 0:
			parts.append("%s %d" % [jewel_name(id), amounts[id]])
	return ", ".join(parts)


# --- The mine's rules ------------------------------------------------------

static func is_boss_floor(level: int) -> bool:
	return level % BOSS_EVERY == 0


## Which zone and which line of LOOT a floor uses.
static func depth_tier(level: int) -> int:
	@warning_ignore("integer_division")
	return (level - 1) / BOSS_EVERY


static func floor_enemies(level: int, rng: RandomNumberGenerator) -> Array:
	var tier := depth_tier(level)
	if is_boss_floor(level):
		return [BOSSES[tier % BOSSES.size()]]
	var pool: Array = zone(level).enemies
	var list := []
	for i in FLOOR_SIZES[(level - 1) % BOSS_EVERY]:
		list.append(pool[rng.randi() % pool.size()])
	return list


static func zone(level: int) -> Dictionary:
	return ZONES[mini(depth_tier(level), ZONES.size() - 1)]


static func floor_strength(level: int) -> float:
	return pow(FLOOR_GROWTH, level - 1)


static func roll_material(tier: int, rng: RandomNumberGenerator) -> String:
	var table: Array = LOOT[clampi(tier, 0, LOOT.size() - 1)]
	var total := 0.0
	for line in table:
		total += line[1]
	var pick := rng.randf() * total
	for line in table:
		pick -= line[1]
		if pick <= 0.0:
			return line[0]
	return table[0][0]


## The next plan the player does not know yet, or "" when all are known.
static func next_plan(known: Array) -> String:
	for plan in PLAN_ORDER:
		if plan not in known:
			return plan
	return ""
