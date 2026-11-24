extends Control
## The forge: choose a plan and a material, then three gestures (heat, hammer, quench).
## Their average note, out of 100, and the weakest of the three decide the rarity
## (see RARITY_RULES in data/catalog.gd). Each gesture starts when GO is pressed.

const Stage := preload("res://scripts/forge_stage.gd")

enum { SELECT, READY, HEAT, HAMMER, QUENCH, PAUSE, RESULT }

## The heat is noted for this long, from the moment the zone is first reached
## (or after HEAT_GRACE seconds at most).
const HEAT_TIME := 5.0
const HEAT_GRACE := 2.5
const HEAT_BAND := 0.11
const STRIKES := 6
const RING_START := 46.0
const RING_TARGET := 14.0
const QUENCH_ZONE := 0.07
const QUENCH_TIME := 6.0

var main: Control

var _state := SELECT
var _plan := "sword"
var _material := "iron"
var _stage: Node2D
var _panel: VBoxContainer
var _gauge: Control
var _hint: Label
var _go: Button
var _next := HEAT

var _clock := 0.0
var _scores := [0.0, 0.0, 0.0]
var _temperature := 0.0
var _band := 0.6
var _in_band := 0.0
var _heat_clock := -1.0
var _strike := 0
var _strike_total := 0.0
var _ring := RING_START
var _ring_wait := 0.0
var _quench_zone := 0.5
var _cursor := 0.0
var _tapped := false
var _after_pause := SELECT
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_stage = Stage.new()
	add_child(_stage)
	var holder := UI.panel()
	holder.position = Vector2(0, Stage.HEIGHT)
	holder.size = Vector2(360, 548 - Stage.HEIGHT)
	add_child(holder)
	_panel = VBoxContainer.new()
	_panel.add_theme_constant_override("separation", 6)
	holder.add_child(_panel)
	if not Save.knows(_plan):
		_plan = Save.plans[0]
	if Save.material_count(_material) < Catalog.FORGE_COST:
		for id in Catalog.MATERIAL_ORDER:
			if Save.material_count(id) >= Catalog.FORGE_COST:
				_material = id
				break
	_show_select()
	if main.auto and Save.material_count(_material) >= Catalog.FORGE_COST:
		_start.call_deferred()


func _exit_tree() -> void:
	main.lock_tabs(false)


# --- Choosing --------------------------------------------------------------

func _show_select() -> void:
	_state = SELECT
	main.lock_tabs(false)
	_stage.hide_weapon()
	UI.clear(_panel)
	_panel.add_child(UI.label("Plan  (les boss en expédition en donnent de nouveaux)", UI.SMALL, UI.DIM))
	var plans := HBoxContainer.new()
	plans.add_theme_constant_override("separation", 3)
	_panel.add_child(plans)
	for id in Catalog.PLAN_ORDER:
		var known := Save.knows(id)
		var button := UI.button("")
		button.custom_minimum_size = Vector2(40, 44)
		button.disabled = not known
		var icon := UI.weapon_icon(id, _material, 0, 1)
		icon.position = Vector2(4, 6)
		icon.size = Vector2(32, 32)
		if not known:
			(icon.material as ShaderMaterial).set_shader_parameter("silhouette", 1.0)
		button.add_child(icon)
		UI.highlight(button, id == _plan)
		button.pressed.connect(func(): _plan = id; _show_select())
		plans.add_child(button)

	_panel.add_child(UI.label("Matériau", UI.SMALL, UI.DIM))
	var materials := GridContainer.new()
	materials.columns = 3
	materials.add_theme_constant_override("h_separation", 3)
	materials.add_theme_constant_override("v_separation", 3)
	_panel.add_child(materials)
	for id in Catalog.MATERIAL_ORDER:
		var count := Save.material_count(id)
		var button := UI.button("%s  %d" % [Catalog.MATERIALS[id].short, count], UI.SMALL)
		button.custom_minimum_size = Vector2(113, 30)
		button.disabled = count < Catalog.FORGE_COST
		button.add_theme_color_override("font_color", Catalog.MATERIALS[id].light)
		UI.highlight(button, id == _material)
		button.pressed.connect(func(): _material = id; _show_select())
		materials.add_child(button)

	var plan: Dictionary = Catalog.PLANS[_plan]
	var mat: Dictionary = Catalog.MATERIALS[_material]
	var element: Dictionary = Catalog.ELEMENTS[mat.element]
	var best: Dictionary = Catalog.RARITIES[mat.max_rarity]
	var what: String = "%s · %s" % [plan.name, mat.name]
	if plan.slot == "weapon":
		what += "\n%s · %s · rareté max %s" % [plan.skill.name, element.name, best.name]
	else:
		what += "\nArmure · rareté max %s" % best.name
	_panel.add_child(UI.centered(what, UI.BODY, element.color))

	var enough := Save.material_count(_material) >= Catalog.FORGE_COST
	var go := UI.button("FORGER  (%d %s)" % [Catalog.FORGE_COST, mat.name] if enough else "Pas assez de matériaux : pars en expédition")
	go.custom_minimum_size.y = 42
	go.disabled = not enough
	go.pressed.connect(_start)
	_panel.add_child(go)


func _start() -> void:
	Save.add_material(_material, -Catalog.FORGE_COST)
	main.lock_tabs(true)
	_stage.show_weapon(_plan, _material, Stage.ANVIL + Vector2(0, -34))
	UI.clear(_panel)
	_hint = UI.centered("", UI.BODY, UI.TEXT, 340.0)
	_hint.custom_minimum_size.y = 70
	_panel.add_child(_hint)
	_gauge = Control.new()
	_gauge.custom_minimum_size = Vector2(340, 124)
	_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge.draw.connect(_draw_gauge)
	_panel.add_child(_gauge)
	_go = UI.button("GO !", UI.BIG)
	_go.custom_minimum_size.y = 56
	UI.highlight(_go, true)
	_go.pressed.connect(_on_go)
	_panel.add_child(_go)
	_prepare(HEAT)


# --- The three gestures ----------------------------------------------------

## Explains the next gesture and waits for the player to press GO.
func _prepare(gesture: int) -> void:
	_state = READY
	_next = gesture
	_go.visible = true
	match gesture:
		HEAT:
			_temperature = 0.0
			_hint.text = "1/3  Chauffe\nMaintiens appuyé pour chauffer, relâche pour refroidir. Reste dans la zone dorée !"
			_stage.move_weapon(Stage.FURNACE + Vector2(30, -14))
		HAMMER:
			_strike = 0
			_hint.text = "2/3  Martelage\nSix coups : touche quand le cercle blanc atteint l'anneau doré."
			_stage.move_weapon(Stage.ANVIL + Vector2(0, -34))
		QUENCH:
			_quench_zone = _rng.randf_range(0.25, 0.75)
			_cursor = 0.0
			_hint.text = "3/3  Trempe\nUn seul essai : touche quand le curseur passe dans la zone bleue."
			_stage.move_weapon(Stage.BARREL + Vector2(0, -40))
	if main.auto and not main.options.has("wait"):
		_on_go.call_deferred()


func _on_go() -> void:
	if _state != READY:
		return
	_go.visible = false
	_clock = 0.0
	_state = _next
	match _next:
		HEAT:
			_in_band = 0.0
			_heat_clock = -1.0
		HAMMER:
			_strike_total = 0.0
			_ring = RING_START
			_ring_wait = 0.6


## Shows a gesture's score for a moment, then goes on.
func _pause(score: float, index: int, next: int) -> void:
	_scores[index] = score
	_state = PAUSE
	_after_pause = next
	_clock = 0.0
	var word := "Parfait !" if score >= 0.85 else ("Bien" if score >= 0.55 else "Raté")
	UI.float_text(self, "%s  %d" % [word, roundi(score * 100)], Vector2(180, 70), _grade_color(score), UI.BIG)
	if index != 2:
		Sfx.play("gesture_done")


func _process(delta: float) -> void:
	_clock += delta
	var tapped := _tapped
	_tapped = false
	match _state:
		HEAT:
			_band = 0.62 + 0.14 * sin(_clock * 1.7)
			var holding := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_pressed("ui_accept")
			if main.auto:
				holding = _temperature < _band
			_temperature = clampf(_temperature + (0.6 if holding else -0.45) * delta, 0.0, 1.0)
			var inside := absf(_temperature - _band) <= HEAT_BAND
			_stage.heat = _temperature
			# Climbing to the zone is not noted: the count starts once it is reached.
			if _heat_clock < 0.0 and (inside or _clock >= HEAT_GRACE):
				_heat_clock = 0.0
			if _heat_clock >= 0.0:
				_heat_clock += delta
				if inside:
					_in_band += delta
				if _heat_clock >= HEAT_TIME:
					_pause(clampf(_in_band / HEAT_TIME, 0.0, 1.0), 0, HAMMER)
		HAMMER:
			if _ring_wait > 0.0:
				_ring_wait -= delta
			else:
				var duration := lerpf(1.0, 0.62, float(_strike) / (STRIKES - 1))
				_ring -= RING_START / duration * delta
				if main.auto and _ring <= RING_TARGET + 1.5:
					tapped = true
				if tapped or _ring <= 0.0:
					_hit(clampf(1.0 - absf(_ring - RING_TARGET) / 22.0, 0.0, 1.0) if tapped else 0.0)
		QUENCH:
			_cursor = pingpong(_clock * 1.5, 1.0)
			var distance := absf(_cursor - _quench_zone)
			if main.auto and distance < 0.04:
				tapped = true
			if tapped or _clock >= QUENCH_TIME:
				var score := 0.0
				if tapped:
					score = 1.0 if distance <= QUENCH_ZONE else clampf(1.0 - (distance - QUENCH_ZONE) / 0.3, 0.0, 1.0)
				_stage.quench()
				Sfx.play("quench")
				_pause(score, 2, RESULT)
		PAUSE:
			if _clock >= 0.9:
				match _after_pause:
					HAMMER: _prepare(HAMMER)
					QUENCH: _prepare(QUENCH)
					RESULT: _show_result()
	if _gauge and is_instance_valid(_gauge):
		_gauge.queue_redraw()


func _hit(accuracy: float) -> void:
	_strike += 1
	_strike_total += accuracy
	_stage.strike(accuracy)
	_stage.heat = _stage.heat - 0.08
	Sfx.play("hammer", 0.85 + accuracy * 0.3)
	if accuracy >= 0.85:
		Sfx.play("hammer_perfect")
	var word := "Parfait !" if accuracy >= 0.85 else ("Bien" if accuracy >= 0.55 else "Raté")
	UI.float_text(self, word, Vector2(180, 110), _grade_color(accuracy))
	_ring = RING_START
	_ring_wait = 0.35
	if _strike >= STRIKES:
		_pause(_strike_total / STRIKES, 1, QUENCH)


func _input(event: InputEvent) -> void:
	if _state != HAMMER and _state != QUENCH:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_tapped = true
	elif event.is_action_pressed("ui_accept"):
		_tapped = true


func _draw_gauge() -> void:
	var width := _gauge.size.x
	var bar := Rect2(10, 40, width - 20, 30)
	match _next if _state == READY else _state:
		HEAT:
			_gauge.draw_rect(bar, UI.INK)
			var cold := Color("3a4a8a")
			var hot := Color("ff6a2a")
			for step in 30:
				_gauge.draw_rect(Rect2(bar.position.x + bar.size.x * step / 30.0, bar.position.y, bar.size.x / 30.0 + 1, bar.size.y), cold.lerp(hot, step / 29.0).darkened(0.45))
			var zone := Rect2(bar.position.x + bar.size.x * (_band - HEAT_BAND), bar.position.y, bar.size.x * HEAT_BAND * 2.0, bar.size.y)
			_gauge.draw_rect(zone, Color(UI.GOLD, 0.45))
			_gauge.draw_rect(zone, UI.GOLD, false, 2.0)
			var x := bar.position.x + bar.size.x * _temperature
			_gauge.draw_rect(Rect2(x - 3, bar.position.y - 8, 6, bar.size.y + 16), Color.WHITE)
			_gauge.draw_rect(bar, UI.EDGE, false, 2.0)
			# Time left.
			_gauge.draw_rect(Rect2(10, 96, (width - 20) * (1.0 - maxf(_heat_clock, 0.0) / HEAT_TIME), 6), UI.DIM)
		HAMMER:
			var center := Vector2(width / 2.0, 58)
			_gauge.draw_circle(center, RING_START + 6, UI.INK)
			_gauge.draw_arc(center, RING_TARGET, 0, TAU, 32, UI.GOLD, 4.0)
			if _ring_wait <= 0.0:
				_gauge.draw_arc(center, maxf(_ring, 1.0), 0, TAU, 48, Color.WHITE, 3.0)
			for index in STRIKES:
				var done := index < _strike
				_gauge.draw_rect(Rect2(width / 2.0 - STRIKES * 9.0 + index * 18.0 + 3, 116, 12, 8), UI.GOLD if done else UI.EDGE)
		QUENCH:
			_gauge.draw_rect(bar, UI.INK)
			var zone := Rect2(bar.position.x + bar.size.x * (_quench_zone - QUENCH_ZONE), bar.position.y, bar.size.x * QUENCH_ZONE * 2.0, bar.size.y)
			_gauge.draw_rect(zone, Color("3fb6ff"))
			var x := bar.position.x + bar.size.x * _cursor
			_gauge.draw_rect(Rect2(x - 3, bar.position.y - 8, 6, bar.size.y + 16), Color.WHITE)
			_gauge.draw_rect(bar, UI.EDGE, false, 2.0)


# --- The finished item -----------------------------------------------------

func _show_result() -> void:
	_state = RESULT
	var score: float = (_scores[0] + _scores[1] + _scores[2]) / 3.0 * 100.0
	var weakest: float = minf(_scores[0], minf(_scores[1], _scores[2])) * 100.0
	var rarity := Catalog.roll_rarity(score, weakest, _material, _rng)
	var item := Save.add_item(_plan, _material, rarity, score)
	var info: Dictionary = Catalog.RARITIES[rarity]
	_stage.reveal(_material, rarity)
	Sfx.play("rarity_%d" % rarity)
	_gauge = null
	UI.clear(_panel)

	_panel.add_child(UI.centered(info.name.to_upper(), UI.BIG, info.color))
	_panel.add_child(UI.centered(Catalog.item_name(item)))
	var lines := "%s\nNote %d / 100\nChauffe %d · Martelage %d · Trempe %d" % [
		Catalog.item_stats(item), roundi(score), roundi(_scores[0] * 100), roundi(_scores[1] * 100), roundi(_scores[2] * 100)]
	_panel.add_child(UI.centered(lines, UI.SMALL, UI.DIM))
	var note := ""
	if Save.last_is_new:
		note = "Nouveau dans l'album !"
	elif Save.last_is_best:
		note = "Meilleure rareté pour cet objet !"
	elif rarity == Catalog.MATERIALS[_material].max_rarity:
		note = "Rareté maximale pour ce matériau."
	_panel.add_child(UI.centered(note, UI.SMALL, UI.GOLD))
	var hint := Catalog.next_rarity_hint(rarity, _material)
	if hint != "":
		_panel.add_child(UI.centered("Pour " + hint, UI.SMALL, UI.DIM))

	var again := UI.button("FORGER ENCORE")
	again.custom_minimum_size.y = 40
	again.pressed.connect(_show_select)
	_panel.add_child(again)
	var mine := UI.button("PARTIR EN EXPÉDITION")
	mine.custom_minimum_size.y = 40
	mine.pressed.connect(func(): main.open("combat"))
	_panel.add_child(mine)
	main.lock_tabs(false)
	print("FORGE %s score=%d rarity=%s %s" % [Catalog.item_name(item), roundi(score), info.name, Catalog.item_stats(item)])
	if main.auto and Save.material_count(_material) >= Catalog.FORGE_COST:
		get_tree().create_timer(1.5).timeout.connect(_start)


func _grade_color(score: float) -> Color:
	return UI.GOLD if score >= 0.85 else (UI.GOOD if score >= 0.55 else UI.BAD)
