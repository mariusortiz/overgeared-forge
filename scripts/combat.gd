extends Control
## The expedition: stage after stage, each one a fight, turn by turn. Basic attacks go by
## themselves when the turn's timer runs out; the player may instead use the weapon's
## skill or switch weapon. After each stage: go on for more loot, or go home
## and keep it. Beaten, Grid loses the materials he was carrying.

enum { IDLE, INTRO, PLAYER, STRIKE, ENEMIES, PARRY, BETWEEN, CHOICE, OVER }

const TURN_TIME := 2.5
## The timing ring: its radius when it appears, and the golden circle's.
const RING_START := 54.0
const RING_TARGET := 16.0
const HERO_AT := Vector2(84, 246)
## Where enemies stand, by how many there are.
const ENEMY_SPOTS := {
	1: [Vector2(268, 246)],
	2: [Vector2(244, 200), Vector2(292, 296)],
	3: [Vector2(226, 172), Vector2(306, 242), Vector2(236, 322)],
}
## With --auto, the game goes back up below this share of its hit points.
const AUTO_LEAVE := 0.3

var main: Control

var _phase := IDLE
var _timer := 0.0
## The timing ring, from 0 (just appeared) to 1 (closed), and what it is for.
var _ring := 0.0
var _ring_time := 1.0
var _ring_style := "steady"
var _tapped := false
var _use_skill := false
var _strike_mult := 1.0
var _attacker := {}
var _floor := 1
var _start_floor := 1
var _hero_hp := 0.0
var _hero_max := 0.0
var _block := 0.0
var _attack_bonus := 1.0
var _guard := 1.0
var _slots: Array = []
var _active := 0
var _target := 0
var _enemies: Array = []
var _enemy_turn := 0
var _loot := {}
var _jewels := {}
var _kill_heal := 0.0
var _new_plan := ""
var _rng := RandomNumberGenerator.new()

var _field: Node2D
var _stage: Stage3D
var _decor := ""
var _hero: Actor
var _title: Label
var _carried: Label
var _hint: Label
var _bars: Control
var _slot_row: HBoxContainer
var _overlay: PanelContainer


func _ready() -> void:
	_rng.randomize()
	_show_entrance()
	if main.auto:
		_begin.call_deferred(int(main.options.get("floor", "1")))


func _exit_tree() -> void:
	main.lock_tabs(false)


# --- Entrance --------------------------------------------------------------

func _show_entrance() -> void:
	var text := "EXPÉDITION\n\nChaque étape est un combat, de plus en plus dur, avec un boss toutes les %d étapes : le canyon de Kesan, les terres du comte Ashur, le temple de Yatan... Plus tu vas loin, meilleurs sont les matériaux.\n\nAprès chaque étape, tu peux rentrer avec ton butin. Si Grid est battu, le butin porté est perdu.\n\nTouche au bon moment pour frapper plus fort et pour parer : chaque ennemi a son rythme." % Catalog.BOSS_EVERY
	if Save.best_floor > 0:
		text += "\n\nRecord : étape %d" % Save.best_floor
	if Save.equipped_items("weapon").is_empty():
		text += "\n\nAucune arme équipée : Grid se battra avec son marteau de forge."
	var box := _open_overlay(text, 16.0)
	# The first floor, and the floors right after the last bosses beaten.
	var floors := Save.start_floors()
	for level in floors.slice(maxi(0, floors.size() - 3)):
		var button := UI.button("PARTIR  ·  étape %d" % level)
		button.custom_minimum_size.y = 42
		button.pressed.connect(_begin.bind(level))
		box.add_child(button)


func _begin(level: int) -> void:
	UI.clear(self)
	_overlay = null
	main.lock_tabs(true)
	_start_floor = level
	_hero_max = Catalog.HERO_HP
	_block = 0.0
	for armor in Save.equipped_protection():
		_hero_max += armor.hp
		_block += Catalog.PLANS[armor.plan].block
	# The jewels of everything equipped add up.
	var bonus := Catalog.jewel_bonus(Save.equipped_items("weapon") + Save.equipped_protection())
	_hero_max += bonus.hp
	_kill_heal = bonus.heal
	_hero_hp = _hero_max
	_attack_bonus = 1.0 + bonus.attack / 100.0
	_guard = 1.0
	_loot = {}
	_jewels = {}
	_slots = []
	for weapon in Save.equipped_items("weapon"):
		_slots.append(weapon.duplicate())
	if _slots.is_empty():
		_slots.append(Catalog.BARE_WEAPON.duplicate())
	for slot in _slots:
		slot["cooldown"] = 0
	_active = 0

	_field = Node2D.new()
	add_child(_field)
	_stage = Stage3D.make(Vector2(360, 400), Vector3(0, 6.0, 14.0), 24.0, 26.0)
	_field.add_child(_stage)
	_hero = Actor.make_hero(_stage, false, 2.0)
	_hero.position = HERO_AT
	_field.add_child(_hero)

	_bars = Control.new()
	_bars.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bars.draw.connect(_draw_bars)
	add_child(_bars)
	_title = UI.label("", UI.BODY, UI.GOLD)
	_title.position = Vector2(8, 4)
	for label in [_title]:
		label.add_theme_color_override("font_outline_color", UI.INK)
		label.add_theme_constant_override("outline_size", 4)
	add_child(_title)
	_carried = UI.label("", UI.SMALL, UI.TEXT)
	_carried.position = Vector2(8, 28)
	_carried.add_theme_color_override("font_outline_color", UI.INK)
	_carried.add_theme_constant_override("outline_size", 4)
	add_child(_carried)
	_hint = UI.centered("", UI.BODY, UI.GOLD, 360.0)
	_hint.position = Vector2(0, 74)
	_hint.add_theme_color_override("font_outline_color", UI.INK)
	_hint.add_theme_constant_override("outline_size", 4)
	add_child(_hint)

	var holder := UI.panel()
	holder.position = Vector2(0, 400)
	holder.size = Vector2(360, 148)
	add_child(holder)
	_slot_row = HBoxContainer.new()
	_slot_row.add_theme_constant_override("separation", 4)
	holder.add_child(_slot_row)
	_enter_floor(level)


# --- Floors ----------------------------------------------------------------

func _enter_floor(level: int) -> void:
	_floor = level
	for enemy in _enemies:
		enemy.sprite.queue_free()
	_enemies = []
	var ids := Catalog.floor_enemies(level, _rng)
	var strength := Catalog.floor_strength(level)
	for i in ids.size():
		var info: Dictionary = Catalog.ENEMIES[ids[i]]
		var boss: bool = info.get("boss", false)
		var sprite := Actor.make(_stage, ids[i], true, 3.0 if boss else 2.0)
		sprite.position = ENEMY_SPOTS[ids.size()][i]
		_field.add_child(sprite)
		sprite.scale = Vector2(0.01, 0.01)
		create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_enemies.append({
			"id": ids[i], "name": info.name, "hp": info.hp * strength, "max": info.hp * strength,
			"attack": info.attack * strength, "weak": info.weak, "sprite": sprite, "boss": boss, "stunned": false,
		})
	_target = 0
	var zone := Catalog.zone(level)
	if zone.backdrop != _decor:
		_decor = zone.backdrop
		Scenery.build(_stage, _decor)
	_title.text = "Étape %d  ·  %s" % [level, "BOSS : " + _enemies[0].name if Catalog.is_boss_floor(level) else zone.name]
	_refresh_carried()
	_refresh_slots()
	_phase = INTRO
	_timer = 0.7


func _process(delta: float) -> void:
	if _field == null:
		return
	_timer -= delta
	match _phase:
		INTRO:
			if _timer <= 0.0:
				_player_turn()
		PLAYER:
			if _timer <= 0.0:
				_act(_best_auto_choice() if main.auto else -1)
		STRIKE:
			_auto_tap()
			_ring += delta / _ring_time
			if _tapped or _ring >= 1.0:
				_strike(_timing_grade())
		ENEMIES:
			if _timer <= 0.0:
				_enemy_attack()
		PARRY:
			_auto_tap()
			_ring += delta / _ring_time
			if _tapped or _ring >= 1.0:
				_phase = ENEMIES
				_enemy_hit(_attacker, _timing_grade())
		BETWEEN:
			if _timer <= 0.0:
				_after_floor()
	_bars.queue_redraw()


func _player_turn() -> void:
	if _first_alive() < 0:
		_phase = BETWEEN
		_timer = 0.6
		return
	if _target < 0 or _target >= _enemies.size() or _enemies[_target].hp <= 0:
		_target = _first_alive()
	_phase = PLAYER
	_timer = 0.3 if main.auto else TURN_TIME
	_refresh_slots()


## One player turn. choice: -1 basic attack, the active slot = its skill,
## another slot = switch to that weapon and strike with it.
func _act(choice: int) -> void:
	if _phase != PLAYER:
		return
	_use_skill = false
	if choice >= 0 and choice != _active:
		_active = choice
		Sfx.play("switch")
		_refresh_slots()
	elif choice == _active and _slots[_active].cooldown <= 0:
		_use_skill = true
	# The game playing by itself gets an ordinary hit, unless asked to time the rings.
	if main.auto and not _auto_rings():
		_strike(1)
		return
	_phase = STRIKE
	_start_ring(Catalog.STRIKE_TIME_BOSS if _enemies[_target].boss else Catalog.STRIKE_TIME, "steady")
	_hint.text = "Touche quand le cercle rejoint l'anneau doré !"


## With --auto --rings, the game times the rings itself, perfectly.
func _auto_rings() -> bool:
	return main.auto and main.options.has("rings")


func _auto_tap() -> void:
	if _auto_rings() and _ring_radius() <= RING_TARGET + 1.5:
		_tapped = true


func _start_ring(seconds: float, style: String) -> void:
	_ring = 0.0
	_ring_time = seconds
	_ring_style = style
	_tapped = false


## The ring's radius now: it closes at the pace of its style.
func _ring_radius() -> float:
	return RING_START * (1.0 - Catalog.ring_progress(_ring_style, clampf(_ring, 0.0, 1.0)))


## 0 missed (or not touched), 1 good, 2 perfect: how well the ring was timed.
func _timing_grade() -> int:
	if not _tapped:
		return 0
	var accuracy := 1.0 - absf(_ring_radius() - RING_TARGET) / 24.0
	return 2 if accuracy >= Catalog.TIMING_PERFECT else (1 if accuracy >= Catalog.TIMING_GOOD else 0)


## The attack lands, stronger or weaker with the timing.
func _strike(grade: int) -> void:
	_hint.text = ""
	_strike_mult = Catalog.STRIKE_DAMAGE[grade]
	if not main.auto or _auto_rings():
		UI.float_text(self, ["Raté", "Bien", "Parfait !"][grade], HERO_AT + Vector2(0, -96), [UI.BAD, UI.GOOD, UI.GOLD][grade])
		if grade == 2:
			Sfx.play("perfect")
	var skill := _use_skill
	for slot in _slots:
		slot.cooldown = maxi(0, slot.cooldown - 1)
	var weapon: Dictionary = _slots[_active]
	var info: Dictionary = Catalog.PLANS[weapon.plan].skill
	if skill:
		weapon.cooldown = info.cooldown
		UI.float_text(self, info.name, HERO_AT + Vector2(0, -70), UI.GOLD)
		match info.kind:
			"all":
				for index in _enemies.size():
					_hit_enemy(index, weapon, info.power)
			"double":
				_hit_enemy(_target, weapon, info.power)
				if _enemies[_target].hp <= 0 and _first_alive() >= 0:
					_target = _first_alive()
				_hit_enemy(_target, weapon, info.power)
			"stun":
				_hit_enemy(_target, weapon, info.power)
				_enemies[_target].stunned = true
			"drain":
				var dealt := _hit_enemy(_target, weapon, info.power)
				_hero_hp = minf(_hero_max, _hero_hp + dealt * 0.5)
				UI.float_text(self, "+%d" % roundi(dealt * 0.5), HERO_AT + Vector2(34, -30), UI.GOOD)
			_:
				_hit_enemy(_target, weapon, info.power)
		Sfx.play("skill")
	else:
		_hit_enemy(_target, weapon, 1.0)
	Sfx.play("hit", _rng.randf_range(0.9, 1.1))
	_hero.attack()
	var lunge := create_tween()
	lunge.tween_property(_hero, "position:x", HERO_AT.x + 30, 0.1)
	lunge.tween_property(_hero, "position:x", HERO_AT.x, 0.2)
	_strike_mult = 1.0
	_refresh_slots()
	_enemy_turn = 0
	_phase = ENEMIES
	_timer = 0.55


## Returns the damage dealt.
func _hit_enemy(index: int, weapon: Dictionary, power: float) -> float:
	var enemy: Dictionary = _enemies[index]
	if enemy.hp <= 0:
		return 0.0
	var element := Catalog.item_element(weapon)
	var weak: bool = element == enemy.weak
	var damage: float = weapon.attack * power * _attack_bonus * _strike_mult * _rng.randf_range(0.9, 1.1)
	if weak:
		damage *= Catalog.WEAK_BONUS
	damage = minf(damage, enemy.hp)
	enemy.hp -= damage
	var sprite: Actor = enemy.sprite
	var color: Color = Catalog.ELEMENTS[element].color
	UI.float_text(self, str(roundi(damage)) + ("!" if weak else ""), sprite.position + Vector2(0, -78), color, UI.BIG if weak else UI.BODY)
	UI.sparks(_field, sprite.position, color, 8)
	if enemy.hp <= 0:
		sprite.fall()
		sprite.create_tween().tween_property(sprite, "scale", Vector2(0.01, 0.01), 0.3).set_delay(1.1)
		_drop(enemy)
	else:
		sprite.hurt()
		if _kill_heal > 0.0 and _hero_hp < _hero_max:
			_hero_hp = minf(_hero_max, _hero_hp + _kill_heal)
			UI.float_text(self, "+%d" % roundi(_kill_heal), HERO_AT + Vector2(-34, -30), UI.GOOD)
	return damage


func _drop(enemy: Dictionary) -> void:
	var tier := Catalog.depth_tier(_floor)
	var count := 1
	if enemy.boss:
		tier += 1
		count = Catalog.BOSS_DROPS
	for i in count:
		var found := Catalog.roll_material(tier, _rng)
		_loot[found] = int(_loot.get(found, 0)) + 1
		UI.float_text(self, "+1 " + Catalog.MATERIALS[found].short, enemy.sprite.position + Vector2(-20, -20 + i * 18), Catalog.MATERIALS[found].light)
	if enemy.boss or _rng.randf() < Catalog.JEWEL_CHANCE:
		var jewel := Catalog.roll_jewel(Catalog.depth_tier(_floor), enemy.boss, _rng)
		_jewels[jewel] = int(_jewels.get(jewel, 0)) + 1
		UI.float_text(self, "+1 " + Catalog.jewel_name(jewel), enemy.sprite.position + Vector2(-20, -44), Catalog.jewel_kind(jewel).color, UI.BIG)
	_refresh_carried()


func _enemy_attack() -> void:
	while _enemy_turn < _enemies.size() and _enemies[_enemy_turn].hp <= 0:
		_enemy_turn += 1
	if _enemy_turn >= _enemies.size():
		_player_turn()
		return
	var enemy: Dictionary = _enemies[_enemy_turn]
	_enemy_turn += 1
	var sprite: Actor = enemy.sprite
	if enemy.stunned:
		enemy.stunned = false
		UI.float_text(self, "Sonné", sprite.position + Vector2(0, -78), UI.DIM)
		_timer = 0.3
		return
	# Every attack can be parried, each enemy at its own rhythm.
	if not main.auto or _auto_rings():
		var rhythm: Array = Catalog.ENEMIES[enemy.id].parry
		_attacker = enemy
		_phase = PARRY
		_start_ring(rhythm[0], rhythm[1])
		_hint.text = "%s attaque : pare !" % enemy.name
		return
	_enemy_hit(enemy, 0)


## An enemy's blow lands, softened by the parry (0 none, 1 good, 2 perfect).
func _enemy_hit(enemy: Dictionary, grade: int) -> void:
	_hint.text = ""
	var sprite: Actor = enemy.sprite
	var damage: float = enemy.attack * _guard * (1.0 - _block) * Catalog.PARRY_DAMAGE[grade] * _rng.randf_range(0.85, 1.15)
	_hero_hp = maxf(0.0, _hero_hp - damage)
	UI.float_text(self, "-" + str(roundi(damage)), HERO_AT + Vector2(0, -54), UI.BAD)
	if grade > 0:
		UI.float_text(self, ["", "Parade", "Parade parfaite !"][grade], HERO_AT + Vector2(0, -96), [UI.BAD, UI.GOOD, UI.GOLD][grade])
		Sfx.play("parry")
	else:
		Sfx.play("hurt", _rng.randf_range(0.9, 1.1))
	sprite.attack()
	var home := sprite.position
	var lunge := sprite.create_tween()
	lunge.tween_property(sprite, "position:x", home.x - 30, 0.1)
	lunge.tween_property(sprite, "position:x", home.x, 0.2)
	if _hero_hp <= 0:
		_hero.fall()
		_finish(false)
	else:
		if grade > 0:
			_hero.block()
		else:
			_hero.hurt()
		_timer = 0.45


# --- Between two floors: go down or go back up -------------------------------

func _after_floor() -> void:
	_phase = CHOICE
	if _floor > Save.best_floor:
		Save.best_floor = _floor
		Save.store()
	# A boss gives a plan, kept whatever happens next.
	_new_plan = ""
	if Catalog.is_boss_floor(_floor):
		_new_plan = Catalog.next_plan(Save.plans)
		Save.learn(_new_plan)
	Sfx.play("plan" if _new_plan != "" else "loot")

	var next := _floor + 1
	var text := "Étape %d terminée" % _floor
	if _new_plan != "":
		text += "\nNouveau plan : %s !" % Catalog.PLANS[_new_plan].name
	text += "\n\nButin porté : %s" % _loot_text(_loot)
	text += "\nVie : %d / %d" % [roundi(_hero_hp), roundi(_hero_max)]
	text += "\n\nContinuer vers l'étape %d%s avec :" % [next, " (boss)" if Catalog.is_boss_floor(next) else ""]
	var box := _open_overlay(text, 24.0)
	for bonus in Catalog.BONUSES:
		var button := UI.button("%s  ·  %s" % [bonus.name, bonus.text], UI.SMALL)
		button.custom_minimum_size.y = 36
		button.pressed.connect(_go_down.bind(bonus.id))
		box.add_child(button)
	box.add_child(UI.centered("ou", UI.SMALL, UI.DIM))
	var leave := UI.button("RENTRER avec le butin")
	leave.custom_minimum_size.y = 42
	leave.add_theme_color_override("font_color", UI.GOLD)
	leave.pressed.connect(_finish.bind(true))
	box.add_child(leave)

	if main.auto:
		var ratio := _hero_hp / _hero_max
		if ratio < AUTO_LEAVE and not main.options.has("deep"):
			_finish.call_deferred(true)
		else:
			_go_down.call_deferred("heal" if ratio < 0.6 else "attack")


func _go_down(bonus: String) -> void:
	if _phase != CHOICE:
		return
	match bonus:
		"heal": _hero_hp = minf(_hero_max, _hero_hp + _hero_max * 0.35)
		"attack": _attack_bonus += 0.15
		"guard": _guard *= 0.9
	Sfx.play("descend")
	_close_overlay()
	_enter_floor(_floor + 1)


## safe: Grid went back up by himself and keeps his loot. Otherwise he was beaten.
func _finish(safe: bool) -> void:
	if _phase == OVER:
		return
	_phase = OVER
	main.lock_tabs(false)
	var cleared := _floor if safe else _floor - 1
	print("MINE start=%d cleared=%d result=%s hp=%d loot=%s jewels=%s" % [_start_floor, cleared, "left" if safe else "beaten", roundi(_hero_hp), _loot, _jewels])
	var text := ""
	if safe:
		for id in _loot:
			Save.add_material(id, _loot[id])
		for id in _jewels:
			Save.add_jewel(id, _jewels[id])
		Sfx.play("leave")
		text = "RETOUR À LA FORGE\n\nButin rapporté : %s\n\nÉtape atteinte : %d  ·  record : %d" % [_loot_text(_loot), cleared, Save.best_floor]
	else:
		Sfx.play("defeat")
		text = "GRID EST BATTU\n\nButin perdu : %s\n\nLes plans trouvés et le record (étape %d) sont gardés." % [_loot_text(_loot), Save.best_floor]
	var box := _open_overlay(text, 110.0)
	var forge := UI.button("ALLER À LA FORGE")
	forge.custom_minimum_size.y = 42
	forge.pressed.connect(func(): main.open("forge"))
	box.add_child(forge)
	var again := UI.button("REPARTIR")
	again.custom_minimum_size.y = 42
	again.pressed.connect(func(): main.open("combat"))
	box.add_child(again)


# --- Helpers ---------------------------------------------------------------

## Everything carried, materials then jewels, as a sentence.
func _loot_text(loot: Dictionary) -> String:
	var jewels := Catalog.jewels_text(_jewels)
	if jewels == "":
		return Catalog.materials_text(loot)
	return jewels if loot.is_empty() else Catalog.materials_text(loot) + ", " + jewels


func _refresh_carried() -> void:
	_carried.text = "Butin porté : " + _loot_text(_loot)


func _first_alive() -> int:
	for index in _enemies.size():
		if _enemies[index].hp > 0:
			return index
	return -1


## What the game plays by itself with --auto: the weapon the target is weak to,
## else the skill when ready, else a basic attack.
func _best_auto_choice() -> int:
	var weak: String = _enemies[_target].weak
	if Catalog.item_element(_slots[_active]) != weak:
		for index in _slots.size():
			if Catalog.item_element(_slots[index]) == weak:
				return index
	return _active if _slots[_active].cooldown <= 0 else -1


func _slot_icon(weapon: Dictionary) -> TextureRect:
	return UI.weapon_icon(weapon.plan, weapon.material, weapon.rarity, 2)


func _refresh_slots() -> void:
	UI.clear(_slot_row)
	var held: Dictionary = _slots[_active]
	_hero.hold(held.plan, held.material, held.rarity)
	# The other weapons wait on his back.
	var others := []
	for index in _slots.size():
		if index != _active:
			others.append(_slots[index])
	_hero.carry(others)
	for index in _slots.size():
		var weapon: Dictionary = _slots[index]
		var skill: Dictionary = Catalog.PLANS[weapon.plan].skill
		var element: Dictionary = Catalog.ELEMENTS[Catalog.item_element(weapon)]
		var button := UI.button("")
		button.custom_minimum_size = Vector2(112, 132)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var column := VBoxContainer.new()
		column.set_anchors_preset(Control.PRESET_FULL_RECT)
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_theme_constant_override("separation", 0)
		var icon := _slot_icon(weapon)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(icon)
		var action := "Changer"
		var usable: bool = index == _active and weapon.cooldown <= 0
		if index == _active:
			action = skill.name if usable else "Prêt dans %d" % weapon.cooldown
		column.add_child(UI.centered("%s · %d" % [element.name, weapon.attack], UI.SMALL, element.color))
		column.add_child(UI.centered(action, UI.BODY, UI.GOLD if usable else UI.DIM))
		button.add_child(column)
		UI.highlight(button, index == _active, Catalog.RARITIES[weapon.rarity].color)
		button.pressed.connect(_act.bind(index))
		_slot_row.add_child(button)


func _input(event: InputEvent) -> void:
	# During a timing ring, a touch anywhere counts.
	if _phase != STRIKE and _phase != PARRY:
		return
	if (event is InputEventMouseButton and event.pressed) or event.is_action_pressed("ui_accept"):
		_tapped = true


func _unhandled_input(event: InputEvent) -> void:
	# Touching an enemy makes it the target.
	if _field == null or not (event is InputEventMouseButton and event.pressed):
		return
	var at: Vector2 = get_local_mouse_position()
	for index in _enemies.size():
		if _enemies[index].hp > 0 and at.distance_to(_enemies[index].sprite.position) < 52.0:
			_target = index


func _draw_bars() -> void:
	for index in _enemies.size():
		var enemy: Dictionary = _enemies[index]
		if enemy.hp <= 0:
			continue
		var at: Vector2 = enemy.sprite.position + Vector2(-48, -96 if enemy.boss else -66)
		_bar(Rect2(at, Vector2(80, 8)), enemy.hp / enemy.max, UI.BAD)
		# The colour of the element the enemy is weak to.
		_bars.draw_rect(Rect2(at + Vector2(84, -2), Vector2(12, 12)), Catalog.ELEMENTS[enemy.weak].color)
		_bars.draw_rect(Rect2(at + Vector2(84, -2), Vector2(12, 12)), UI.INK, false, 2.0)
		if index == _target and _phase != OVER:
			_bars.draw_rect(Rect2(at + Vector2(-4, -4), Vector2(104, 16)), UI.GOLD, false, 2.0)
	_bar(Rect2(HERO_AT + Vector2(-60, 60), Vector2(120, 10)), _hero_hp / _hero_max, UI.GOOD)
	var life := "%s  %d/%d" % [Catalog.HERO_NAME, roundi(_hero_hp), roundi(_hero_max)]
	_bars.draw_string_outline(get_theme_default_font(), HERO_AT + Vector2(-60, 90), life, HORIZONTAL_ALIGNMENT_CENTER, 120, UI.BODY, 4, UI.INK)
	_bars.draw_string(get_theme_default_font(), HERO_AT + Vector2(-60, 90), life, HORIZONTAL_ALIGNMENT_CENTER, 120, UI.BODY, UI.TEXT)
	if _phase == PLAYER:
		_bar(Rect2(8, 388, 344, 6), _timer / TURN_TIME, UI.GOLD)
	# The timing ring: on the target when striking, on Grid when parrying.
	if _phase == STRIKE or _phase == PARRY:
		var center := HERO_AT
		if _phase == STRIKE and _target >= 0 and _target < _enemies.size():
			center = _enemies[_target].sprite.position
		_bars.draw_circle(center, RING_TARGET + 2.0, Color(0, 0, 0, 0.35))
		_bars.draw_arc(center, RING_TARGET, 0, TAU, 32, UI.GOLD, 4.0)
		_bars.draw_arc(center, maxf(_ring_radius(), 1.0), 0, TAU, 48, Color.WHITE if _phase == STRIKE else UI.BAD, 3.0)


func _bar(rect: Rect2, ratio: float, color: Color) -> void:
	_bars.draw_rect(rect, UI.INK)
	_bars.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(ratio, 0.0, 1.0), rect.size.y)), color)
	_bars.draw_rect(rect, UI.EDGE, false, 2.0)


func _open_overlay(text: String, top: float) -> VBoxContainer:
	_close_overlay()
	_overlay = UI.panel(Color(UI.PANEL, 0.97), UI.GOLD)
	_overlay.position = Vector2(20, top)
	_overlay.custom_minimum_size = Vector2(320, 0)
	add_child(_overlay)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_overlay.add_child(box)
	box.add_child(UI.centered(text, UI.BODY, UI.TEXT, 304.0))
	return box


func _close_overlay() -> void:
	if _overlay:
		_overlay.queue_free()
		_overlay = null
