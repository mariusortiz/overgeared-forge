extends Control
## The album: one square for each plan and material, with the best rarity forged so far.

var main: Control


func _ready() -> void:
	var total := Catalog.PLAN_ORDER.size() * Catalog.MATERIAL_ORDER.size()
	var title := UI.label("ALBUM  %d/%d" % [Save.album.size(), total], 16, UI.GOLD)
	title.position = Vector2(8, 6)
	add_child(title)

	var grid := GridContainer.new()
	grid.columns = Catalog.MATERIAL_ORDER.size()
	grid.position = Vector2(6, 34)
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	add_child(grid)
	for plan in Catalog.PLAN_ORDER:
		for material in Catalog.MATERIAL_ORDER:
			var best := int(Save.album.get(Catalog.album_key(plan, material), -1))
			var found := best >= 0
			var cell := UI.panel(UI.PANEL, Catalog.RARITIES[best].color if found else UI.PANEL_LIGHT)
			cell.custom_minimum_size = Vector2(84, 104)
			var column := VBoxContainer.new()
			column.alignment = BoxContainer.ALIGNMENT_CENTER
			column.add_theme_constant_override("separation", 2)
			cell.add_child(column)
			var icon := UI.weapon_icon(plan, material, maxi(best, 0), 2)
			icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			if not found:
				(icon.material as ShaderMaterial).set_shader_parameter("silhouette", 1.0)
			column.add_child(icon)
			# One pip for each rarity; those reached are lit.
			var pips := HBoxContainer.new()
			pips.alignment = BoxContainer.ALIGNMENT_CENTER
			pips.add_theme_constant_override("separation", 2)
			for rarity in Catalog.RARITIES.size():
				var pip := ColorRect.new()
				pip.custom_minimum_size = Vector2(8, 8)
				pip.color = Catalog.RARITIES[rarity].color if rarity <= best else UI.PANEL_LIGHT
				pips.add_child(pip)
			column.add_child(pips)
			var caption := UI.label(Catalog.RARITIES[best].name if found else "?", 16, Catalog.RARITIES[best].color if found else UI.DIM)
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			caption.clip_text = true
			column.add_child(caption)
			cell.tooltip_text = "%s · %s" % [Catalog.PLANS[plan].name, Catalog.MATERIALS[material].name]
			grid.add_child(cell)

	var legend := UI.label("Lignes : épée, dague, lance, hache.\nColonnes : fer, acier ardent,\ngivre-argent, orichalque bleu.", 16, UI.DIM)
	legend.position = Vector2(8, 484)
	add_child(legend)
