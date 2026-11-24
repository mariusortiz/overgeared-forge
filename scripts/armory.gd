extends Control
## The weapons the player owns: equip up to three, melt the others back into material.

var main: Control
var _list: VBoxContainer
var _title: Label


func _ready() -> void:
	_title = UI.label("", 16, UI.GOLD)
	_title.position = Vector2(8, 6)
	add_child(_title)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(4, 30)
	scroll.size = Vector2(352, 514)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)
	_refresh()


func _refresh() -> void:
	UI.clear(_list)
	_title.text = "ARMES  %d · équipées %d/%d" % [Save.weapons.size(), Save.equipped.size(), Catalog.MAX_EQUIPPED]
	if Save.weapons.is_empty():
		_list.add_child(UI.label("\nAucune arme pour l'instant.\nVa à la forge !", 16, UI.DIM))
		return
	var sorted := Save.weapons.duplicate()
	sorted.sort_custom(func(a, b): return a.attack > b.attack)
	for weapon in sorted:
		var rarity: Dictionary = Catalog.RARITIES[weapon.rarity]
		var element: Dictionary = Catalog.ELEMENTS[Catalog.weapon_element(weapon)]
		var equipped := Save.is_equipped(weapon.uid)
		var row := UI.panel(UI.PANEL, rarity.color if equipped else UI.EDGE)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 6)
		row.add_child(line)
		line.add_child(UI.weapon_icon(weapon.plan, weapon.material, weapon.rarity, 2))
		var texts := VBoxContainer.new()
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texts.add_theme_constant_override("separation", 0)
		var weapon_name := UI.label(Catalog.weapon_name(weapon), 16)
		weapon_name.clip_text = true
		texts.add_child(weapon_name)
		texts.add_child(UI.label(rarity.name, 16, rarity.color))
		var stats := UI.label("Attaque %d · %s" % [weapon.attack, element.name], 16, element.color)
		stats.clip_text = true
		texts.add_child(stats)
		line.add_child(texts)
		var buttons := VBoxContainer.new()
		var equip := UI.button("RETIRER" if equipped else "ÉQUIPER")
		equip.custom_minimum_size = Vector2(84, 30)
		equip.disabled = not equipped and Save.equipped.size() >= Catalog.MAX_EQUIPPED
		equip.pressed.connect(func(): Save.toggle_equipped(weapon.uid); _refresh())
		buttons.add_child(equip)
		var melt := UI.button("FONDRE")
		melt.custom_minimum_size = Vector2(84, 30)
		melt.tooltip_text = "Rend 1 %s" % Catalog.MATERIALS[weapon.material].name
		melt.pressed.connect(func(): _melt(weapon))
		buttons.add_child(melt)
		line.add_child(buttons)
		_list.add_child(row)


## Melting a weapon gives one unit of its material back. The album keeps its entry.
func _melt(weapon: Dictionary) -> void:
	Save.remove_weapon(weapon.uid)
	Save.add_material(weapon.material, 1)
	Sfx.play("metalPot2", 0.7)
	_refresh()
