extends Control
## The mine: five waves fought turn by turn. Basic attacks go by themselves when the
## turn's timer runs out; the player may instead use the weapon's skill or switch weapon.

enum { INTRO, PLAYER, ENEMIES, BETWEEN, BONUS, OVER }

const TURN_TIME := 2.5
const HERO_AT := Vector2(180, 290)
const ENEMY_Y := 150.0

var main: Control

var _phase := INTRO
var _timer := 0.0
var _wave := 0
var _level := 1
var _hero_hp := 0.0
var _hero_max := 0.0
var _attack_bonus := 1.0
var _guard := 1.0
var _slots: Array = []
var _active := 0
var _target := 0
var _enemies: Array = []
var _enemy_turn := 0
var _loot := {}
var _rng := RandomNumberGenerator.new()

var _field: Node2D
var _hero: Sprite2D
var _held: Sprite2D
var _title: Label
var _bars: Control
var _slot_row: HBoxContainer
var _overlay: PanelContainer


func _ready() -> void:
	_rng.randomize()
	if Save.equipped_weapons().is_empty():
		_show_message("Aucune arme équipée.\nForge une arme, ou équipe-en une dans ARMES.", "ALLER À LA FORGE", func(): main.open("forge"))
		return
	_show_message("MINE DU NORD\nNiveau %d\n\n5 vagues, un boss à la dernière.\nChaque ennemi craint un élément." % Save.mine_level, "ENTRER", _begin)
	if main.auto:
		_begin.call_deferred()


func _exit_tree() -> void:
	main.lock_tabs(false)


func _begin() -> void:
	UI.clear(self)
	_overlay = null
	main.lock_tabs(true)
	_level = Save.mine_level
	_hero_max = Catalog.HERO_HP
	_hero_hp = _hero_max
	_attack_bonus = 1.0
	_guard = 1.0
	_loot = {}
	_slots = []
	for weapon in Save.equipped_weapons():
		var slot: Dictionary = weapon.duplicate()
		slot["cooldown"] = 0
		_slots.append(slot)
	_active = 0

	_field = Node2D.new()
	_field.draw.connect(_draw_field)
	add_child(_field)
	_hero = UI.tile_sprite(Catalog.HERO_TILE, 5.0)
	_hero.position = HERO_AT
	_field.add_child(_hero)
	_held = Sprite2D.new()
	_held.position = HERO_AT + Vector2(46, -14)
	_held.scale = Vector2(2, 2)
	_field.add_child(_held)

	_bars = Control.new()
	_bars.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bars.draw.connect(_draw_bars)
	add_child(_bars)
	_title = UI.label("", 16, UI.GOLD)
	_title.position = Vector2(8, 6)
	add_child(_title)
	var flee := UI.button("FUIR")
	flee.position = Vector2(292, 4)
	flee.size = Vector2(60, 26)
	flee.pressed.connect(func(): _finish(false))
	add_child(flee)

	var holder := UI.panel()
	holder.position = Vector2(0, 400)
	holder.size = Vector2(360, 148)
	add_child(holder)
	_slot_row = HBoxContainer.new()
	_slot_row.add_theme_constant_override("separation", 4)
	holder.add_child(_slot_row)
	_start_wave(0)


# --- Waves -----------------------------------------------------------------

func _start_wave(index: int) -> void:
	_wave = index
	for enemy in _enemies:
		enemy.sprite.queue_free()
	_enemies = []
	var ids: Array = Catalog.WAVES[index]
	var growth := pow(Catalog.LEVEL_GROWTH, _level - 1)
	for i in ids.size():
		var info: Dictionary = Catalog.ENEMIES[ids[i]]
		var boss: bool = info.get("boss", false)
		var sprite := UI.tile_sprite(info.tile, 8.0 if boss else 4.0)
		sprite.position = Vector2(180.0 + (i - (ids.size() - 1) / 2.0) * 104.0, ENEMY_Y - (30.0 if boss else 0.0))
		_field.add_child(sprite)
		sprite.modulate.a = 0.0
		create_tween().tween_property(sprite, "modulate:a", 1.0, 0.3)
		_enemies.append({
			"id": ids[i], "name": info.name, "hp": info.hp * growth, "max": info.hp * growth,
			"attack": info.attack * growth, "weak": info.weak, "sprite": sprite, "boss": boss,
		})
	_target = 0
	_title.text = "Niveau %d · Vague %d/%d" % [_level, index + 1, Catalog.WAVES.size()]
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
				_after_wave()
	_bars.queue_redraw()
	_field.queue_redraw()


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
		Sfx.play("drawKnife1")
	elif choice == _active and _slots[_active].cooldown <= 0:
		skill = true
	for slot in _slots:
		slot.cooldown = maxi(0, slot.cooldown - 1)
	var weapon: Dictionary = _slots[_active]
	var info: Dictionary = Catalog.PLANS[weapon.plan].skill
	if skill:
		weapon.cooldown = info.cooldown
		UI.float_text(self, info.name, HERO_AT + Vector2(0, -60), UI.GOLD)
		match info.kind:
			"all":
				for index in _enemies.size():
					_hit_enemy(index, weapon, info.power)
			"double":
				_hit_enemy(_target, weapon, info.power)
				if _enemies[_target].hp <= 0 and _first_alive() >= 0:
					_target = _first_alive()
				_hit_enemy(_target, weapon, info.power)
			_:
				_hit_enemy(_target, weapon, info.power)
	else:
		_hit_enemy(_target, weapon, 1.0)
	Sfx.play("knifeSlice2" if skill else "knifeSlice", _rng.randf_range(0.9, 1.1))
	var lunge := create_tween()
	lunge.tween_property(_hero, "position:y", HERO_AT.y - 22, 0.08)
	lunge.tween_property(_hero, "position:y", HERO_AT.y, 0.15)
	_refresh_slots()
	_enemy_turn = 0
	_phase = ENEMIES
	_timer = 0.55


func _hit_enemy(index: int, weapon: Dictionary, power: float) -> void:
	var enemy: Dictionary = _enemies[index]
	if enemy.hp <= 0:
		return
	var element := Catalog.weapon_element(weapon)
	var weak: bool = element == enemy.weak
	var damage: float = weapon.attack * power * _attack_bonus * _rng.randf_range(0.9, 1.1)
	if weak:
		damage *= Catalog.WEAK_BONUS
	enemy.hp = maxf(0.0, enemy.hp - damage)
	var sprite: Sprite2D = enemy.sprite
	var color: Color = Catalog.ELEMENTS[element].color
	UI.float_text(self, str(roundi(damage)) + ("!" if weak else ""), sprite.position + Vector2(0, -34), color, 24 if weak else 16)
	UI.sparks(_field, sprite.position, color, 8)
	var flash := sprite.create_tween()
	flash.tween_property(sprite, "modulate", Color(3, 3, 3), 0.05)
	flash.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	if enemy.hp <= 0:
		flash.tween_property(sprite, "modulate:a", 0.0, 0.25)
		_drop(enemy)


func _drop(enemy: Dictionary) -> void:
	var info: Dictionary = Catalog.ENEMIES[enemy.id]
	for i in info.get("drop_count", 1):
		for line in info.drops:
			if _rng.randf() <= line[1]:
				_loot[line[0]] = int(_loot.get(line[0], 0)) + 1
				UI.float_text(self, "+1 " + Catalog.MATERIALS[line[0]].name, enemy.sprite.position + Vector2(0, 20 + i * 16), Catalog.MATERIALS[line[0]].light)
				break


func _enemy_attack() -> void:
	while _enemy_turn < _enemies.size() and _enemies[_enemy_turn].hp <= 0:
		_enemy_turn += 1
	if _enemy_turn >= _enemies.size():
		_player_turn()
		return
	var enemy: Dictionary = _enemies[_enemy_turn]
	_enemy_turn += 1
	var damage: float = enemy.attack * _guard * _rng.randf_range(0.85, 1.15)
	_hero_hp = maxf(0.0, _hero_hp - damage)
	UI.float_text(self, "-" + str(roundi(damage)), HERO_AT + Vector2(0, -44), UI.BAD)
	Sfx.play("chop", _rng.randf_range(0.8, 1.0), -4.0)
	var sprite: Sprite2D = enemy.sprite
	var home := sprite.position
	var lunge := sprite.create_tween()
	lunge.tween_property(sprite, "position:y", home.y + 26, 0.08)
	lunge.tween_property(sprite, "position:y", home.y, 0.15)
	var flash := _hero.create_tween()
	flash.tween_property(_hero, "modulate", Color(2.5, 0.6, 0.6), 0.05)
	flash.tween_property(_hero, "modulate", Color.WHITE, 0.2)
	if _hero_hp <= 0:
		_finish(false)
	else:
		_timer = 0.45


func _after_wave() -> void:
	if _wave + 1 >= Catalog.WAVES.size():
		_finish(true)
		return
	_phase = BONUS
	var box := _open_overlay("VAGUE %d TERMINÉE\nChoisis un bonus :" % (_wave + 1))
	for bonus in Catalog.BONUSES:
		var button := UI.button("%s\n%s" % [bonus.name, bonus.text])
		button.custom_minimum_size.y = 52
		button.pressed.connect(_take_bonus.bind(bonus.id))
		box.add_child(button)
	if main.auto:
		_take_bonus.call_deferred("heal" if _hero_hp < _hero_max * 0.6 else "attack")


func _take_bonus(id: String) -> void:
	if _phase != BONUS:
		return
	match id:
		"heal": _hero_hp = minf(_hero_max, _hero_hp + _hero_max * 0.4)
		"attack": _attack_bonus += 0.25
		"guard": _guard *= 0.8
	Sfx.play("bookFlip1")
	_close_overlay()
	_start_wave(_wave + 1)


func _finish(won: bool) -> void:
	if _phase == OVER:
		return
	_phase = OVER
	main.lock_tabs(false)
	# A lost or abandoned run still brings back half of what was picked up.
	var lines := ""
	for id in Catalog.MATERIAL_ORDER:
		var count := int(_loot.get(id, 0))
		if not won:
			@warning_ignore("integer_division")
			count = count / 2
		if count > 0:
			Save.add_material(id, count)
			lines += "+%d %s\n" % [count, Catalog.MATERIALS[id].name]
	if lines == "":
		lines = "Aucun butin.\n"
	if won:
		Save.mine_level = _level + 1
		Save.store()
	print("COMBAT level=%d won=%s wave=%d hp=%d loot=%s" % [_level, won, _wave + 1, roundi(_hero_hp), _loot])
	var title := "VICTOIRE !\nLa mine passe au niveau %d." % (_level + 1) if won else "RETOUR À LA FORGE\nLa moitié du butin est gardée."
	var box := _open_overlay(title + "\n\n" + lines)
	var again := UI.button("REPARTIR À LA MINE")
	again.custom_minimum_size.y = 40
	again.pressed.connect(func(): main.open("combat"))
	box.add_child(again)
	var forge := UI.button("ALLER À LA FORGE")
	forge.custom_minimum_size.y = 40
	forge.pressed.connect(func(): main.open("forge"))
	box.add_child(forge)
	if main.auto and won and options_loop():
		get_tree().create_timer(1.0).timeout.connect(func(): main.open("combat"))


func options_loop() -> bool:
	return main.options.has("loop")


# --- Helpers ---------------------------------------------------------------

func _first_alive() -> int:
	for index in _enemies.size():
		if _enemies[index].hp > 0:
			return index
	return -1


## What the game plays by itself with --auto: the skill when ready, else the
## weapon the target is weak to, else a basic attack.
func _best_auto_choice() -> int:
	var weak: String = _enemies[_target].weak
	for index in _slots.size():
		if index != _active and Catalog.weapon_element(_slots[index]) == weak and Catalog.weapon_element(_slots[_active]) != weak:
			return index
	return _active if _slots[_active].cooldown <= 0 else -1


func _refresh_slots() -> void:
	UI.clear(_slot_row)
	_held.texture = UI.weapon_texture(_slots[_active].plan)
	_held.material = UI.weapon_material(_slots[_active].material, _slots[_active].rarity)
	for index in _slots.size():
		var weapon: Dictionary = _slots[index]
		var skill: Dictionary = Catalog.PLANS[weapon.plan].skill
		var element: Dictionary = Catalog.ELEMENTS[Catalog.weapon_element(weapon)]
		var button := UI.button("")
		button.custom_minimum_size = Vector2(112, 132)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var column := VBoxContainer.new()
		column.set_anchors_preset(Control.PRESET_FULL_RECT)
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_theme_constant_override("separation", 0)
		var icon := UI.weapon_icon(weapon.plan, weapon.material, weapon.rarity, 2)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(icon)
		var action := "CHANGER"
		if index == _active:
			action = skill.name if weapon.cooldown <= 0 else "Prêt dans %d" % weapon.cooldown
		for text in [[element.name + " · " + str(weapon.attack), element.color], [action, UI.GOLD if index == _active and weapon.cooldown <= 0 else UI.DIM]]:
			var line := UI.label(text[0], 16, text[1])
			line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			line.clip_text = true
			column.add_child(line)
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
		if _enemies[index].hp > 0 and at.distance_to(_enemies[index].sprite.position) < 48.0:
			_target = index


func _draw_field() -> void:
	var wall := UI.tile_texture(40)
	var ground := UI.tile_texture(0)
	for column in 8:
		for row in 2:
			_field.draw_texture_rect(wall, Rect2(column * 48.0, row * 48.0 - 16.0, 48, 48), false, Color(0.3, 0.28, 0.42))
		for row in 7:
			_field.draw_texture_rect(ground, Rect2(column * 48.0, 80.0 + row * 48.0, 48, 48), false, Color(0.42, 0.36, 0.44))
	_field.draw_rect(Rect2(0, 76, 360, 4), Color(0.08, 0.06, 0.1))
	for enemy in _enemies:
		if enemy.hp > 0:
			_field.draw_circle(enemy.sprite.position + Vector2(0, 30 if not enemy.boss else 60), 26 if not enemy.boss else 48, Color(0, 0, 0, 0.25))
	_field.draw_circle(HERO_AT + Vector2(0, 38), 30, Color(0, 0, 0, 0.25))


func _draw_bars() -> void:
	for index in _enemies.size():
		var enemy: Dictionary = _enemies[index]
		if enemy.hp <= 0:
			continue
		var at: Vector2 = enemy.sprite.position + Vector2(-40, 44 if not enemy.boss else 74)
		_bar(Rect2(at, Vector2(80, 8)), enemy.hp / enemy.max, UI.BAD)
		# The colour of the element the enemy is weak to.
		_bars.draw_rect(Rect2(at + Vector2(84, -2), Vector2(12, 12)), Catalog.ELEMENTS[enemy.weak].color)
		_bars.draw_rect(Rect2(at + Vector2(84, -2), Vector2(12, 12)), UI.INK, false, 2.0)
		if index == _target and _phase != OVER:
			_bars.draw_rect(Rect2(at + Vector2(-4, -4), Vector2(104, 16)), UI.GOLD, false, 2.0)
	_bar(Rect2(HERO_AT + Vector2(-60, 48), Vector2(120, 10)), _hero_hp / _hero_max, UI.GOOD)
	_bars.draw_string(get_theme_default_font(), HERO_AT + Vector2(-60, 76), "%s  %d/%d" % [Catalog.HERO_NAME, roundi(_hero_hp), roundi(_hero_max)], HORIZONTAL_ALIGNMENT_CENTER, 120, 16, UI.TEXT)
	if _phase == PLAYER:
		_bar(Rect2(8, 388, 344, 6), _timer / TURN_TIME, UI.GOLD)


func _bar(rect: Rect2, ratio: float, color: Color) -> void:
	_bars.draw_rect(rect, UI.INK)
	_bars.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(ratio, 0.0, 1.0), rect.size.y)), color)
	_bars.draw_rect(rect, UI.EDGE, false, 2.0)


func _open_overlay(text: String) -> VBoxContainer:
	_close_overlay()
	_overlay = UI.panel(Color(UI.PANEL, 0.96), UI.GOLD)
	_overlay.position = Vector2(30, 90)
	_overlay.custom_minimum_size = Vector2(300, 0)
	add_child(_overlay)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_overlay.add_child(box)
	var label := UI.label(text, 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 284
	box.add_child(label)
	return box


func _close_overlay() -> void:
	if _overlay:
		_overlay.queue_free()
		_overlay = null


func _show_message(text: String, action: String, callback: Callable) -> void:
	var box := _open_overlay(text)
	var button := UI.button(action)
	button.custom_minimum_size.y = 44
	button.pressed.connect(callback)
	box.add_child(button)
