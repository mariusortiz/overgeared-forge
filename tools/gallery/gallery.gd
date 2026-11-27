extends Node2D
## A check sheet, not part of the game: every character, or every weapon, or a decor.
## godot --path . res://tools/gallery/gallery.tscn -- --test --show=characters|weapons|<decor> --capture=/path.png

func _ready() -> void:
	var show := "characters"
	var capture := ""
	for option in OS.get_cmdline_user_args():
		if option.begins_with("--show="):
			show = option.trim_prefix("--show=")
		if option.begins_with("--capture="):
			capture = option.trim_prefix("--capture=")
	var stage := Stage3D.make(Vector2(360, 640), Vector3(0, 9.0, 16.0), 32.0, 30.0)
	add_child(stage)
	if show == "characters":
		Scenery._ground(stage, "grass", Color.WHITE)
		var ids := Models.CHARACTERS.keys()
		for index in ids.size():
			var actor := Actor.make(stage, ids[index], index % 2 == 1, 2.0)
			actor.position = Vector2(50 + (index % 4) * 86, 60 + (index / 4) * 150)
			add_child(actor)
			var label := Label.new()
			label.text = ids[index]
			label.position = actor.position + Vector2(-36, 58)
			add_child(label)
	elif show == "weapons":
		Scenery._ground(stage, "sand", Color.WHITE)
		var keys := Models.WEAPONS.keys()
		var materials := Catalog.MATERIALS.keys()
		for index in keys.size():
			var node := Models.weapon(keys[index], materials[index % materials.size()], index % 6)
			node.position = stage.at_depth(Vector2(50 + (index % 4) * 86, 90 + (index / 4) * 72), 0.0)
			node.rotation_degrees.y = 25
			stage.world.add_child(node)
			var label := Label.new()
			label.text = keys[index]
			label.position = Vector2(20 + (index % 4) * 86, 96 + (index / 4) * 72)
			add_child(label)
	else:
		stage.size = Vector2(360, 400)
		Scenery.build(stage, show)
	if capture != "":
		await get_tree().create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(capture)
		get_tree().quit()
