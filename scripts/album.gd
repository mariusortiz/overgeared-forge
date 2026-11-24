extends Control
## The album: one square for each plan (lines) and material (columns), with the
## best rarity forged so far.

const CELL := 55.0

var main: Control
var _caption: Label


func _ready() -> void:
	var total := Catalog.PLAN_ORDER.size() * Catalog.MATERIAL_ORDER.size()
	var title := UI.label("Album  %d/%d  ·  Plans  %d/%d" % [Save.album.size(), total, Save.plans.size(), Catalog.PLAN_ORDER.size()], UI.BODY, UI.GOLD)
	title.position = Vector2(8, 4)
	add_child(title)

	var grid := GridContainer.new()
	grid.columns = Catalog.MATERIAL_ORDER.size()
	grid.position = Vector2(6, 32)
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	add_child(grid)
	for plan in Catalog.PLAN_ORDER:
		for material in Catalog.MATERIAL_ORDER:
			var best := int(Save.album.get(Catalog.album_key(plan, material), -1))
			var found := best >= 0
			var cell := Button.new()
			cell.focus_mode = Control.FOCUS_NONE
			cell.custom_minimum_size = Vector2(CELL, CELL)
			var style := UI.box(UI.PANEL, Catalog.RARITIES[best].color if found else UI.PANEL_LIGHT)
			for state in ["normal", "hover", "pressed"]:
				cell.add_theme_stylebox_override(state, style)
			var icon := UI.weapon_icon(plan, material, maxi(best, 0), 1)
			icon.position = Vector2((CELL - 32) / 2.0, 5)
			icon.size = Vector2(32, 32)
			if not found:
				(icon.material as ShaderMaterial).set_shader_parameter("silhouette", 1.0)
			cell.add_child(icon)
			# One pip for each rarity; those reached are lit.
			for rarity in Catalog.RARITIES.size():
				var pip := ColorRect.new()
				pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
				pip.position = Vector2(5 + rarity * 7.5, CELL - 12)
				pip.size = Vector2(6, 6)
				pip.color = Catalog.RARITIES[rarity].color if rarity <= best else UI.PANEL_LIGHT
				cell.add_child(pip)
			cell.pressed.connect(_describe.bind(plan, material, best))
			grid.add_child(cell)

	_caption = UI.centered("Touche une case pour voir de quoi il s'agit.", UI.BODY, UI.DIM, 348.0)
	_caption.position = Vector2(6, 500)
	add_child(_caption)


func _describe(plan: String, material: String, best: int) -> void:
	var text := "%s · %s" % [Catalog.PLANS[plan].name if Save.knows(plan) else "Plan inconnu", Catalog.MATERIALS[material].name]
	if best >= 0:
		_caption.text = "%s\nMeilleure rareté : %s" % [text, Catalog.RARITIES[best].name]
		_caption.add_theme_color_override("font_color", Catalog.RARITIES[best].color)
	else:
		_caption.text = text + "\n" + ("Pas encore forgé" if Save.knows(plan) else "Bats les boss en expédition pour trouver ce plan")
		_caption.add_theme_color_override("font_color", UI.DIM)
	Sfx.play("click")
