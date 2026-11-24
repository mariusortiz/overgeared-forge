extends Control
## The inventory: a limited number of items. Equip up to three weapons and one
## armour, melt the rest back into material.

var main: Control
var _list: VBoxContainer
var _title: Label
var _overlay: ColorRect


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
	# --jewels opens the jewel panel of the first item that has room for one.
	if main.options.has("jewels"):
		for item in Save.items:
			if Catalog.SOCKETS[item.rarity] > 0:
				_open_jewels(item)
				break


func _refresh() -> void:
	UI.clear(_list)
	_title.text = "Inventaire %d/%d  ·  Armes %d/%d  ·  Armure %d/%d" % [
		Save.items.size(), Save.capacity(),
		Save.equipped_items("weapon").size(), Catalog.SLOT_LIMITS.weapon,
		Save.equipped_items("armor").size(), Catalog.SLOT_LIMITS.armor]
	_title.add_theme_color_override("font_color", UI.BAD if Save.is_full() else UI.GOLD)
	var stock := Catalog.jewels_text(Save.jewels)
	_list.add_child(UI.label("Joyaux : " + (stock if stock != "" else "aucun (les boss en lâchent)"), UI.SMALL, UI.TEXT if stock != "" else UI.DIM))
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
		for text in [[Catalog.item_name(item), UI.TEXT], ["%s · note %d" % [rarity.name, item.score], rarity.color], [Catalog.item_stats(item), element.color if Catalog.is_weapon(item) else UI.GOOD]]:
			var label := UI.label(text[0], UI.BODY, text[1])
			label.clip_text = true
			texts.add_child(label)
		var last := HBoxContainer.new()
		last.add_theme_constant_override("separation", 3)
		# One square for each place a jewel can be set in.
		for index in Catalog.SOCKETS[item.rarity]:
			var socket := ColorRect.new()
			socket.custom_minimum_size = Vector2(10, 10)
			socket.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			socket.color = Catalog.jewel_kind(item.jewels[index]).color if index < item.jewels.size() else UI.PANEL_LIGHT
			last.add_child(socket)
		last.add_child(UI.label("Fonte : " + Catalog.materials_text(Catalog.melt_yield(item)), UI.SMALL, UI.DIM))
		texts.add_child(last)
		line.add_child(texts)
		var buttons := VBoxContainer.new()
		buttons.add_theme_constant_override("separation", 2)
		var equip := UI.button("Retirer" if equipped else "Équiper", UI.SMALL)
		equip.custom_minimum_size = Vector2(76, 28)
		equip.disabled = not equipped and not Save.can_equip(item)
		equip.pressed.connect(func(): Save.toggle_equipped(item); _refresh())
		buttons.add_child(equip)
		var melt := UI.button("Fondre", UI.SMALL)
		melt.custom_minimum_size = Vector2(76, 28)
		melt.pressed.connect(func(): _melt(item))
		buttons.add_child(melt)
		if Catalog.SOCKETS[item.rarity] > 0:
			var jewels := UI.button("Sertir", UI.SMALL)
			jewels.custom_minimum_size = Vector2(76, 28)
			jewels.pressed.connect(func(): _open_jewels(item))
			buttons.add_child(jewels)
		line.add_child(buttons)
		_list.add_child(row)


## Melting an item gives materials back, finer ones for a high rarity (see MELT
## in data/catalog.gd). The album keeps its entry.
func _melt(item: Dictionary) -> void:
	var gained := Catalog.melt_yield(item)
	Save.remove_item(item.uid)
	for id in gained:
		Save.add_material(id, gained[id])
	UI.float_text(self, "+ " + Catalog.materials_text(gained), Vector2(180, 60), UI.GOLD)
	Sfx.play("melt")
	_refresh()


# --- Setting jewels --------------------------------------------------------

## A panel over the list: the item's jewels, and the stock to pick from.
func _open_jewels(item: Dictionary) -> void:
	if _overlay:
		_overlay.queue_free()
	# A dark veil over the list, so that nothing behind can be pressed.
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.65)
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := UI.panel(UI.PANEL, UI.GOLD)
	panel.position = Vector2(20, 40)
	panel.custom_minimum_size = Vector2(320, 0)
	_overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	box.add_child(UI.centered(Catalog.item_name(item), UI.BODY, Catalog.RARITIES[item.rarity].color, 304.0))
	box.add_child(UI.centered("Emplacements : %d / %d" % [item.jewels.size(), Catalog.SOCKETS[item.rarity]], UI.SMALL, UI.DIM))
	for id in item.jewels:
		box.add_child(UI.centered("%s  ·  %s" % [Catalog.jewel_name(id), Catalog.jewel_effect(id)], UI.SMALL, Catalog.jewel_kind(id).color))

	var any := false
	for id in Catalog.all_jewels():
		if Save.jewel_count(id) == 0:
			continue
		any = true
		var button := UI.button("%s x%d  ·  %s" % [Catalog.jewel_name(id), Save.jewel_count(id), Catalog.jewel_effect(id)], UI.SMALL)
		button.custom_minimum_size.y = 32
		button.add_theme_color_override("font_color", Catalog.jewel_kind(id).color)
		button.disabled = Save.free_sockets(item) <= 0
		button.pressed.connect(func(): Save.set_jewel(item, id); Sfx.play("loot"); _open_jewels(item))
		box.add_child(button)
	if not any:
		box.add_child(UI.centered("Aucun joyau en réserve.\nLes boss en lâchent un à chaque fois.", UI.SMALL, UI.DIM, 304.0))

	if not item.jewels.is_empty():
		var take := UI.button("Retirer les joyaux", UI.SMALL)
		take.custom_minimum_size.y = 32
		take.pressed.connect(func(): Save.take_jewels(item); _open_jewels(item))
		box.add_child(take)
	box.add_child(UI.centered("Les joyaux de tout ce que Grid porte s'additionnent.", UI.SMALL, UI.DIM, 304.0))
	var close := UI.button("FERMER")
	close.custom_minimum_size.y = 40
	close.pressed.connect(func(): _overlay.queue_free(); _overlay = null; _refresh())
	box.add_child(close)
