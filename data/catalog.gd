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
## dark and light: the colours the metal of a weapon takes.
const MATERIALS := {
	"iron": {"name": "Fer", "short": "Fer", "element": "none", "power": 1.0, "max_rarity": 2,
		"dark": Color("55566a"), "light": Color("e7f0f4")},
	"ember": {"name": "Acier ardent", "short": "Ardent", "element": "fire", "power": 1.25, "max_rarity": 3,
		"dark": Color("6e2a1e"), "light": Color("ffc078")},
	"frost": {"name": "Givre-argent", "short": "Givre", "element": "ice", "power": 1.25, "max_rarity": 3,
		"dark": Color("2f5f86"), "light": Color("e2fbff")},
	"storm": {"name": "Pierre d'orage", "short": "Orage", "element": "lightning", "power": 1.25, "max_rarity": 3,
		"dark": Color("4a2a80"), "light": Color("e6ccff")},
	"mithril": {"name": "Mithril", "short": "Mithril", "element": "none", "power": 1.6, "max_rarity": 4,
		"dark": Color("2f6a62"), "light": Color("e6fff4")},
	"orichalcum": {"name": "Orichalque bleu", "short": "Orichalque", "element": "lightning", "power": 2.0, "max_rarity": 4,
		"dark": Color("2a2f9a"), "light": Color("9fd0ff")},
}
const MATERIAL_ORDER := ["iron", "ember", "frost", "storm", "mithril", "orichalcum"]
## Only this material can give a mythic item.
const MYTH_MATERIAL := "orichalcum"

## Weapons have an attack and a skill; armours have hit points and may block.
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
	"plate": {"name": "Plastron", "slot": "armor", "sprite": "plate", "hp": 25, "block": 0.0},
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
const SLOT_LIMITS := {"weapon": 3, "armor": 1}

const HERO_NAME := "Grid"
const HERO_TILE := 98
const HERO_HP := 120
## Without any weapon, Grid fights with his forge hammer.
const BARE_WEAPON := {"uid": 0, "plan": "sword", "material": "iron", "rarity": 0, "attack": 6, "bare": true}
const WEAK_BONUS := 1.5

# --- The mine --------------------------------------------------------------

## Every floor is a fight; every BOSS_EVERY floors, a boss. Enemies get this
## much stronger at each floor.
const BOSS_EVERY := 5
const FLOOR_GROWTH := 1.1
## How many enemies on the floors before a boss.
const FLOOR_SIZES := [2, 2, 3, 3]

## tile: the sprite's number in assets/tiles/tiny_dungeon.png.
const ENEMIES := {
	"slime": {"name": "Slime", "tile": 108, "hp": 24, "attack": 3, "weak": "fire"},
	"bat": {"name": "Chauve-souris", "tile": 120, "hp": 20, "attack": 4, "weak": "ice"},
	"spider": {"name": "Araignée", "tile": 122, "hp": 30, "attack": 5, "weak": "lightning"},
	"rat": {"name": "Rat", "tile": 123, "hp": 26, "attack": 5, "weak": "fire"},
	"ghost": {"name": "Fantôme", "tile": 121, "hp": 30, "attack": 6, "weak": "lightning"},
	"crab": {"name": "Crabe", "tile": 110, "hp": 40, "attack": 5, "weak": "ice"},
	"bandit": {"name": "Pillard", "tile": 112, "hp": 36, "attack": 7, "weak": "fire"},
	"cultist": {"name": "Sorcier", "tile": 111, "hp": 32, "attack": 8, "weak": "ice"},
	"cyclops": {"name": "Cyclope", "tile": 109, "hp": 160, "attack": 9, "weak": "ice", "boss": true},
	"mimic": {"name": "Coffre vorace", "tile": 92, "hp": 170, "attack": 10, "weak": "fire", "boss": true},
	"warlock": {"name": "Mage noir", "tile": 84, "hp": 180, "attack": 11, "weak": "lightning", "boss": true},
}
## One line for every BOSS_EVERY floors; the last line serves for all deeper floors.
const ENEMY_POOLS := [
	["slime", "bat", "spider"],
	["rat", "ghost", "crab", "spider"],
	["ghost", "crab", "bandit", "cultist"],
]
const BOSSES := ["cyclops", "mimic", "warlock"]

## What an enemy drops, by depth: [material, weight]. Same lines as ENEMY_POOLS.
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


## The rarity of a forged item, from the score (0 to 100) of the three gestures.
static func roll_rarity(score: float, material: String, rng: RandomNumberGenerator) -> int:
	var quality := score + rng.randf_range(-8.0, 8.0)
	var rarity := 0
	for threshold in [45.0, 62.0, 76.0, 88.0]:
		if quality >= threshold:
			rarity += 1
	var mat: Dictionary = MATERIALS[material]
	rarity = mini(rarity, mat.max_rarity)
	# A near-perfect forge with the best material can go beyond legendary.
	if material == MYTH_MATERIAL and score >= 92.0 and rng.randf() < 0.15:
		rarity = MYTH
	return rarity


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


static func album_key(plan: String, material: String) -> String:
	return plan + ":" + material


# --- The mine's rules ------------------------------------------------------

static func is_boss_floor(level: int) -> bool:
	return level % BOSS_EVERY == 0


## Which line of ENEMY_POOLS and LOOT a floor uses.
static func depth_tier(level: int) -> int:
	@warning_ignore("integer_division")
	return (level - 1) / BOSS_EVERY


static func floor_enemies(level: int, rng: RandomNumberGenerator) -> Array:
	var tier := depth_tier(level)
	if is_boss_floor(level):
		return [BOSSES[tier % BOSSES.size()]]
	var pool: Array = ENEMY_POOLS[mini(tier, ENEMY_POOLS.size() - 1)]
	var list := []
	for i in FLOOR_SIZES[(level - 1) % BOSS_EVERY]:
		list.append(pool[rng.randi() % pool.size()])
	return list


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
