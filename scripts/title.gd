extends Control
## The title screen, shown over everything when the game opens.

const Stage := preload("res://scripts/forge_stage.gd")

var _reset: Button
var _asked := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = UI.INK
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var title := UI.centered("OVERGEARED", 60, UI.GOLD, 360.0)
	title.position = Vector2(0, 44)
	add_child(title)
	var subtitle := UI.centered("F O R G E", UI.BIG, UI.TEXT, 360.0)
	subtitle.position = Vector2(0, 104)
	add_child(subtitle)

	# The workshop, alive, as the picture of the screen.
	# (In a holder: the stage moves itself when it shakes.)
	var holder := Node2D.new()
	holder.position = Vector2(0, 160)
	add_child(holder)
	holder.add_child(Stage.new())
	for edge in [158.0, 160.0 + Stage.HEIGHT]:
		var line := ColorRect.new()
		line.color = UI.GOLD
		line.position = Vector2(0, edge)
		line.size = Vector2(360, 2)
		add_child(line)

	var play := UI.button("JOUER", UI.BIG)
	play.position = Vector2(60, 440)
	play.size = Vector2(240, 60)
	UI.highlight(play, true)
	play.pressed.connect(queue_free)
	add_child(play)

	# Offered only when there is something to lose.
	if not Save.items.is_empty() or Save.best_floor > 0:
		_reset = UI.button("Nouvelle partie", UI.SMALL)
		_reset.position = Vector2(110, 512)
		_reset.size = Vector2(140, 30)
		_reset.pressed.connect(_on_reset)
		add_child(_reset)

	var notice := UI.centered("Jeu de fans gratuit et non officiel,\ninspiré de l'anime Overgeared.", UI.SMALL, UI.DIM, 360.0)
	notice.position = Vector2(0, 584)
	add_child(notice)


## The first press asks, the second one erases the progress.
func _on_reset() -> void:
	if not _asked:
		_asked = true
		_reset.text = "Tout effacer ? Appuie encore"
		_reset.position.x = 70
		_reset.size.x = 220
		_reset.add_theme_color_override("font_color", UI.BAD)
		return
	Save.reset()
	Save.store()
	_reset.queue_free()
