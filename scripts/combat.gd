extends Control
## The expedition: stage after stage, each one a fight, turn by turn. Basic attacks go by
## themselves when the turn's timer runs out; the player may instead use the weapon's
## skill or switch weapon. After each stage: go on for more loot, or go home
## and keep it. Beaten, Grid loses the materials he was carrying.

enum { IDLE, INTRO, PLAYER, ENEMIES, BETWEEN, CHOICE, OVER }

const TURN_TIME := 2.5
const HERO_AT := Vector2(84, 246)
## Where enemies stand, by how many there are.
const ENEMY_SPOTS := {
	1: [Vector2(268, 246)],
	2: [Vector2(244, 200), Vector2(292, 296)],
	3: [Vector2(236, 176), Vector2(300, 246), Vector2(240, 316)],
}
## With --auto, the game goes back up below this share of its hit points.
const AUTO_LEAVE := 0.3

var main: Control

var _phase := IDLE
var _timer := 0.0
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
var _new_plan := ""
var _rng := RandomNumberGenerator.new()

var _field: Node2D
var _backdrop: Sprite2D
var _hero: Actor
var _title: Label
var _carried: Label
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
	var text := "EXPÉDITION\n\nChaque étape est un combat, de plus en plus dur, avec un boss toutes les %d étapes : le canyon de Kesan, les terres du comte Ashur, le temple de Yatan... Plus tu vas loin, meilleurs sont les matériaux.\n\nAprès chaque étape, tu peux rentrer avec ton butin. Si Grid est battu, le butin porté est perdu." % Catalog.BOSS_EVERY
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
	for armor in Save.equipped_items("armor"):
		_hero_max += armor.hp
		_block += Catalog.PLANS[armor.plan].block
	_hero_hp = _hero_max
	_attack_bonus = 1.0
	_guard = 1.0
	_loot = {}
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
	_backdrop = Sprite2D.new()
	_backdrop.centered = false
	_backdrop.scale = Vector2(2, 2)
	_field.add_child(_backdrop)
	_hero = Actor.make(Catalog.HERO_SPRITE, false, 2.0)
	_hero.position = HERO_AT
	_field.add_child(_hero)

	_bars = Control.new()
	_bars.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bars.draw.connect(_draw_bars)
	add_child(_bars)
	_title = UI.label("", UI.BODY, UI.GOLD)
	_title.position = Vector2(8, 4)
	add_child(_title)
	_carried = UI.label("", UI.SMALL, UI.TEXT)
	_carried.position = Vector2(8, 28)
	add_child(_carried)

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
		var sprite := Actor.make(info.sprite, true, 3.0 if boss else 2.0)
		sprite.hold(UI.picture(info.weapon), UI.weapon_material("iron", 0))
		sprite.position = ENEMY_SPOTS[ids.size()][i]
		_field.add_child(sprite)
		sprite.modulate.a = 0.0
		create_tween().tween_property(sprite, "modulate:a", 1.0, 0.3)
		_enemies.append({
			"id": ids[i], "name": info.name, "hp": info.hp * strength, "max": info.hp * strength,
			"attack": info.attack * strength, "weak": info.weak, "sprite": sprite, "boss": boss, "stunned": false,
		})
	_target = 0
	var zone := Catalog.zone(level)
	_backdrop.texture = load("res://assets/lpc/backdrops/%s.png" % zone.backdrop)
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
		ENEMIES:
			if _timer <= 0.0:
				_enemy_attack()
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
	var skill := false
	if choice >= 0 and choice != _active:
		_active = choice
		Sfx.play("switch")
	elif choice == _active and _slots[_active].cooldown <= 0:
		skill = true
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
	var damage: float = weapon.attack * power * _attack_bonus * _rng.randf_range(0.9, 1.1)
	if weak:
		damage *= Catalog.WEAK_BONUS
	damage = minf(damage, enemy.hp)
	enemy.hp -= damage
	var sprite: Actor = enemy.sprite
	var color: Color = Catalog.ELEMENTS[element].color
	UI.float_text(self, str(roundi(damage)) + ("!" if weak else ""), sprite.position + Vector2(0, -78), color, UI.BIG if weak else UI.BODY)
	UI.sparks(_field, sprite.position, color, 8)
	var flash := sprite.create_tween()
	flash.tween_property(sprite, "modulate", Color(3, 3, 3), 0.05)
	flash.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	if enemy.hp <= 0:
		sprite.fall()
		flash.tween_property(sprite, "modulate:a", 0.0, 0.3).set_delay(0.45)
		_drop(enemy)
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
	var damage: float = enemy.attack * _guard * (1.0 - _block) * _rng.randf_range(0.85, 1.15)
	_hero_hp = maxf(0.0, _hero_hp - damage)
	UI.float_text(self, "-" + str(roundi(damage)), HERO_AT + Vector2(0, -54), UI.BAD)
	Sfx.play("hurt", _rng.randf_range(0.9, 1.1))
	sprite.attack()
	var home := sprite.position
	var lunge := sprite.create_tween()
	lunge.tween_property(sprite, "position:x", home.x - 30, 0.1)
	lunge.tween_property(sprite, "position:x", home.x, 0.2)
	var flash := _hero.create_tween()
	flash.tween_property(_hero, "modulate", Color(2.5, 0.6, 0.6), 0.05)
	flash.tween_property(_hero, "modulate", Color.WHITE, 0.2)
	if _hero_hp <= 0:
		_hero.fall()
		_finish(false)
	else:
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
	print("MINE start=%d cleared=%d result=%s hp=%d loot=%s" % [_start_floor, cleared, "left" if safe else "beaten", roundi(_hero_hp), _loot])
	var text := ""
	if safe:
		for id in _loot:
			Save.add_material(id, _loot[id])
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

func _loot_text(loot: Dictionary) -> String:
	var parts := []
	for id in Catalog.MATERIAL_ORDER:
		if int(loot.get(id, 0)) > 0:
			parts.append("%s %d" % [Catalog.MATERIALS[id].short, loot[id]])
	return "rien" if parts.is_empty() else ", ".join(parts)


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
	_hero.hold(UI.weapon_texture(held.plan), UI.weapon_material(held.material, held.rarity))
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
	_bars.draw_string(get_theme_default_font(), HERO_AT + Vector2(-60, 90), "%s  %d/%d" % [Catalog.HERO_NAME, roundi(_hero_hp), roundi(_hero_max)], HORIZONTAL_ALIGNMENT_CENTER, 120, UI.BODY, UI.TEXT)
	if _phase == PLAYER:
		_bar(Rect2(8, 388, 344, 6), _timer / TURN_TIME, UI.GOLD)


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
