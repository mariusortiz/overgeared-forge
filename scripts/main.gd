extends Control
## The frame around every screen: materials at the top, tabs at the bottom.
##
## Command line, after "--":
##   --screen=forge|combat|armory|album   opens on that screen, without the title
##   --auto      the game plays by itself (forge gestures, combat choices; it
##               comes back from the expedition when its hit points get low)
##   --demo      starts with a few weapons and materials
##   --basic     starts with what six iron give: two average iron weapons
##   --mid       starts with a mid-game set (elemental weapons, a shield)
##   --floor=6   with --auto, the stage the expedition starts at
##   --jewels    with --screen=armory, opens the jewel panel of an item
##   --rings     with --auto, the timing rings of fights are shown and timed perfectly
##   --wait      with --auto, the forge waits on its GO button (for pictures)
##   --deep      with --auto, never comes back: goes on until beaten
##   --test      does not read or write the save file
##   --capture=/path.png [--delay=2]   saves a picture of the window, then quits

const SCREENS := {
	"forge": preload("res://scripts/forge.gd"),
	"combat": preload("res://scripts/combat.gd"),
	"armory": preload("res://scripts/armory.gd"),
	"album": preload("res://scripts/album.gd"),
}
const Title := preload("res://scripts/title.gd")
const TABS := [["forge", "FORGE"], ["combat", "EXPÉDITION"], ["armory", "INVENTAIRE"], ["album", "ALBUM"]]
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
	if options.has("mid"):
		Save.materials = {"iron": 0}
		Save.plans = ["sword", "dagger", "spear", "shield"]
		Save.best_floor = 5
		Save.add_item("sword", "ember", 2, 70)
		Save.add_item("dagger", "frost", 2, 70)
		Save.add_item("spear", "storm", 2, 70)
		Save.add_item("shield", "iron", 2, 70)
	if options.has("basic"):
		# What a new player owns after three average forges.
		Save.materials = {"iron": 0}
		Save.add_item("sword", "iron", 1, 60)
		Save.add_item("dagger", "iron", 1, 60)

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
	_chips.add_theme_constant_override("separation", 16)
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
	# The title screen, unless the command line asks for a screen or for --auto.
	if not options.has("screen") and not auto:
		add_child(Title.new())

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
	Save.materials = {"iron": 12, "ember": 7, "frost": 5, "storm": 4, "mithril": 3, "orichalcum": 3}
	Save.plans = ["sword", "dagger", "spear", "shield", "axe", "plate"]
	Save.best_floor = 12
	Save.add_item("sword", "ember", 3, 84)
	Save.add_item("spear", "frost", 2, 71)
	Save.add_item("axe", "orichalcum", 4, 93)
	Save.add_item("plate", "mithril", 3, 80)
	Save.add_item("dagger", "iron", 1, 58)
	Save.add_item("sword", "iron", 0, 31)
	Save.add_item("shield", "storm", 2, 66)
	Save.add_item("dagger", "orichalcum", 5, 97)
	Save.jewels = {"ruby:0": 2, "sapphire:1": 1, "emerald:2": 1}
	Save.set_jewel(Save.items[2], "ruby:0")
	Save.set_jewel(Save.items[0], "sapphire:1")
