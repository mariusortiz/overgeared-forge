extends Control
## What the player owns: equip up to three weapons and one armour, melt the rest
## back into material.

var main: Control
var _list: VBoxContainer
var _title: Label


func _ready() -> void:
	_title = UI.label("", UI.BODY, UI.GOLD)
	_title.position = Vector2(8, 4)
	add_child(_title)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(4, 32)
	scroll.size = Vector2(352, 512)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)
	_refresh()


func _refresh() -> void:
	UI.clear(_list)
	_title.text = "Armes %d/%d  ·  Armure %d/%d" % [
		Save.equipped_items("weapon").size(), Catalog.SLOT_LIMITS.weapon,
		Save.equipped_items("armor").size(), Catalog.SLOT_LIMITS.armor]
	if Save.items.is_empty():
		_list.add_child(UI.label("\nRien pour l'instant.\nVa à la forge !", UI.BODY, UI.DIM))
		return
	# Equipped first, then the strongest.
	var sorted := Save.items.duplicate()
	sorted.sort_custom(func(a, b):
		if Save.is_equipped(a.uid) != Save.is_equipped(b.uid):
			return Save.is_equipped(a.uid)
		return a.attack + a.hp > b.attack + b.hp)
	for item in sorted:
		var rarity: Dictionary = Catalog.RARITIES[item.rarity]
		var element: Dictionary = Catalog.ELEMENTS[Catalog.item_element(item)]
		var equipped := Save.is_equipped(item.uid)
		var row := UI.panel(UI.PANEL, rarity.color if equipped else UI.EDGE)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 6)
		row.add_child(line)
		line.add_child(UI.weapon_icon(item.plan, item.material, item.rarity, 2))
		var texts := VBoxContainer.new()
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texts.add_theme_constant_override("separation", -2)
		for text in [[Catalog.item_name(item), UI.TEXT], [rarity.name, rarity.color], [Catalog.item_stats(item), element.color if Catalog.is_weapon(item) else UI.GOOD]]:
			var label := UI.label(text[0], UI.BODY, text[1])
			label.clip_text = true
			texts.add_child(label)
		line.add_child(texts)
		var buttons := VBoxContainer.new()
		var equip := UI.button("Retirer" if equipped else "Équiper", UI.SMALL)
		equip.custom_minimum_size = Vector2(76, 30)
		equip.disabled = not equipped and not Save.can_equip(item)
		equip.pressed.connect(func(): Save.toggle_equipped(item); _refresh())
		buttons.add_child(equip)
		var melt := UI.button("Fondre", UI.SMALL)
		melt.custom_minimum_size = Vector2(76, 30)
		melt.pressed.connect(func(): _melt(item))
		buttons.add_child(melt)
		line.add_child(buttons)
		_list.add_child(row)


## Melting an item gives one unit of its material back. The album keeps its entry.
func _melt(item: Dictionary) -> void:
	Save.remove_item(item.uid)
	Save.add_material(item.material, 1)
	Sfx.play("melt")
	_refresh()
