extends Control
## The frame around every screen: materials at the top, tabs at the bottom.
##
## Command line, after "--":
##   --screen=forge|combat|armory|album   opens on that screen
##   --auto      the game plays by itself (forge gestures, combat choices)
##   --demo      starts with a few weapons and materials
##   --basic     starts with three average iron weapons
##   --loop      with --auto, goes back into the mine after each victory
##   --test      does not read or write the save file
##   --capture=/path.png [--delay=2]   saves a picture of the window, then quits

const SCREENS := {
	"forge": preload("res://scripts/forge.gd"),
	"combat": preload("res://scripts/combat.gd"),
	"armory": preload("res://scripts/armory.gd"),
	"album": preload("res://scripts/album.gd"),
}
const TABS := [["forge", "FORGE"], ["combat", "MINE"], ["armory", "ARMES"], ["album", "ALBUM"]]
const TOP := 36.0
const BOTTOM := 56.0

var auto := false
var options := {}

var _content: Control
var _chips: HBoxContainer
var _tab_buttons := {}
var _current := ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		options[parts[0]] = parts[1] if parts.size() > 1 else ""
	auto = options.has("auto")
	if options.has("demo"):
		_fill_demo()
	if options.has("basic"):
		# What a new player owns after three average forges.
		Save.materials = {"iron": 0}
		Save.add_weapon("sword", "iron", 1, 60)
		Save.add_weapon("dagger", "iron", 1, 60)
		Save.add_weapon("spear", "iron", 1, 60)

	var background := ColorRect.new()
	background.color = UI.INK
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var top := UI.panel(UI.PANEL, UI.PANEL)
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.custom_minimum_size.y = TOP
	add_child(top)
	_chips = HBoxContainer.new()
	_chips.alignment = BoxContainer.ALIGNMENT_CENTER
	_chips.add_theme_constant_override("separation", 22)
	top.add_child(_chips)

	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.offset_top = TOP
	_content.offset_bottom = -BOTTOM
	_content.clip_contents = true
	add_child(_content)

	var tabs := HBoxContainer.new()
	tabs.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tabs.offset_top = -BOTTOM
	tabs.add_theme_constant_override("separation", 0)
	add_child(tabs)
	for tab in TABS:
		var button := UI.button(tab[1])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(open.bind(tab[0]))
		tabs.add_child(button)
		_tab_buttons[tab[0]] = button

	Save.changed.connect(_refresh_chips)
	_refresh_chips()
	open(options.get("screen", "forge"))

	if options.has("capture"):
		await get_tree().create_timer(float(options.get("delay", "2"))).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(options["capture"])
		get_tree().quit()


func open(screen: String) -> void:
	if not SCREENS.has(screen):
		screen = "forge"
	_current = screen
	UI.clear(_content)
	var node: Control = SCREENS[screen].new()
	node.main = self
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.add_child(node)
	for id in _tab_buttons:
		UI.highlight(_tab_buttons[id], id == screen)


## Tabs are greyed out while a forge or a fight is going on.
func lock_tabs(locked: bool) -> void:
	for id in _tab_buttons:
		_tab_buttons[id].disabled = locked


func _refresh_chips() -> void:
	UI.clear(_chips)
	for id in Catalog.MATERIAL_ORDER:
		var chip := UI.material_chip(id, Save.material_count(id))
		chip.tooltip_text = Catalog.MATERIALS[id].name
		_chips.add_child(chip)


func _fill_demo() -> void:
	Save.materials = {"iron": 12, "ember": 7, "frost": 5, "orichalcum": 3}
	Save.add_weapon("sword", "ember", 3, 84)
	Save.add_weapon("spear", "frost", 2, 71)
	Save.add_weapon("axe", "orichalcum", 4, 93)
	Save.add_weapon("dagger", "iron", 1, 58)
	Save.add_weapon("sword", "iron", 0, 31)
	Save.add_weapon("dagger", "orichalcum", 5, 97)
