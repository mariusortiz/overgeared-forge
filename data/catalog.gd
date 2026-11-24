class_name Catalog
## The game's content: rarities, materials, plans, enemies, waves.
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
const MATERIALS := {
	"iron": {"name": "Fer", "element": "none", "power": 1.0, "max_rarity": 2,
		"dark": Color("55566a"), "light": Color("e7f0f4")},
	"ember": {"name": "Acier ardent", "element": "fire", "power": 1.25, "max_rarity": 3,
		"dark": Color("6e2a1e"), "light": Color("ffc078")},
	"frost": {"name": "Givre-argent", "element": "ice", "power": 1.25, "max_rarity": 3,
		"dark": Color("2f5f86"), "light": Color("e2fbff")},
	"orichalcum": {"name": "Orichalque bleu", "element": "lightning", "power": 1.6, "max_rarity": 4,
		"dark": Color("2a2f9a"), "light": Color("9fd0ff")},
}
const MATERIAL_ORDER := ["iron", "ember", "frost", "orichalcum"]

## Skill kinds: "single" (one enemy), "double" (two hits), "all" (every enemy).
const PLANS := {
	"sword": {"name": "Épée", "sprite": "sword5", "attack": 12,
		"skill": {"name": "Taillade", "kind": "single", "power": 2.0, "cooldown": 2}},
	"dagger": {"name": "Dague", "sprite": "dagger3", "attack": 9,
		"skill": {"name": "Double frappe", "kind": "double", "power": 1.1, "cooldown": 2}},
	"spear": {"name": "Lance", "sprite": "spear1", "attack": 10,
		"skill": {"name": "Percée", "kind": "all", "power": 0.9, "cooldown": 2}},
	"axe": {"name": "Hache", "sprite": "axe3", "attack": 14,
		"skill": {"name": "Fendoir", "kind": "single", "power": 3.0, "cooldown": 4}},
}
const PLAN_ORDER := ["sword", "dagger", "spear", "axe"]

const FORGE_COST := 3
const MAX_EQUIPPED := 3
const START_MATERIALS := {"iron": 9}

const HERO_NAME := "Grid"
const HERO_TILE := 98
const HERO_HP := 120
const WEAK_BONUS := 1.5
## Enemies get this much stronger at each level of the mine.
const LEVEL_GROWTH := 1.25

## tile: the sprite's number in assets/tiles/tiny_dungeon.png.
## drops: one line is drawn for each enemy beaten, [material, chances].
const ENEMIES := {
	"slime": {"name": "Slime", "tile": 108, "hp": 24, "attack": 3, "weak": "fire",
		"drops": [["iron", 1.0]]},
	"bat": {"name": "Chauve-souris", "tile": 120, "hp": 20, "attack": 4, "weak": "ice",
		"drops": [["ember", 0.6], ["iron", 1.0]]},
	"spider": {"name": "Araignée", "tile": 122, "hp": 30, "attack": 5, "weak": "lightning",
		"drops": [["frost", 0.6], ["iron", 1.0]]},
	"boss": {"name": "Cyclope", "tile": 109, "hp": 160, "attack": 9, "weak": "ice", "boss": true,
		"drops": [["orichalcum", 1.0]], "drop_count": 3},
}
const WAVES := [
	["slime", "slime"],
	["slime", "bat"],
	["bat", "spider"],
	["spider", "slime", "bat"],
	["boss"],
]

## What the player picks between two waves.
const BONUSES := [
	{"id": "heal", "name": "Potion", "text": "Rend 40 % des points de vie"},
	{"id": "attack", "name": "Aiguisage", "text": "+25 % d'attaque"},
	{"id": "guard", "name": "Armure", "text": "-20 % de dégâts reçus"},
]


## The rarity of a forged weapon, from the score (0 to 100) of the three gestures.
static func roll_rarity(score: float, material: String, rng: RandomNumberGenerator) -> int:
	var quality := score + rng.randf_range(-8.0, 8.0)
	var rarity := 0
	for threshold in [45.0, 62.0, 76.0, 88.0]:
		if quality >= threshold:
			rarity += 1
	var mat: Dictionary = MATERIALS[material]
	rarity = mini(rarity, mat.max_rarity)
	# A near-perfect forge with the best material can go beyond legendary.
	if material == "orichalcum" and score >= 92.0 and rng.randf() < 0.15:
		rarity = MYTH
	return rarity


static func weapon_attack(plan: String, material: String, rarity: int, score: float) -> int:
	var value: float = PLANS[plan].attack * MATERIALS[material].power * RARITIES[rarity].mult
	return roundi(value * (0.9 + score / 500.0))


static func weapon_name(weapon: Dictionary) -> String:
	return "%s · %s" % [PLANS[weapon.plan].name, MATERIALS[weapon.material].name]


static func weapon_element(weapon: Dictionary) -> String:
	return MATERIALS[weapon.material].element


static func album_key(plan: String, material: String) -> String:
	return plan + ":" + material
