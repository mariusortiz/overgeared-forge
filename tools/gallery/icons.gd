extends Node
## Draws the menu picture of every plan from its 3D model, into assets/icons.
## Run after changing a weapon model:
## godot --path . res://tools/gallery/icons.tscn -- --test

const SIZE := 192
## The model fills this share of the picture; the rest is room for the outline.
const FILL := 0.8


func _ready() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(SIZE, SIZE)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.0
	camera.position = Vector3(0, 0, 10)
	viewport.add_child(camera)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.55
	var holder := WorldEnvironment.new()
	holder.environment = environment
	viewport.add_child(holder)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	sun.light_energy = 0.8
	viewport.add_child(sun)

	for plan in Catalog.PLAN_ORDER:
		var pivot := Node3D.new()
		viewport.add_child(pivot)
		var model := Models.weapon(plan)
		pivot.add_child(model)
		# Weapons lean like on a rack; armour and shields face the player.
		if Catalog.PLANS[plan].slot == "weapon":
			pivot.rotation_degrees = Vector3(0, 0, -45)
		else:
			pivot.rotation_degrees = Vector3(10, -25, 0)
		var box := _bounds(pivot)
		var span := maxf(box.size.x, box.size.y)
		pivot.scale = Vector3.ONE * (2.0 * FILL / span)
		pivot.position = -box.get_center() * pivot.scale.x
		pivot.position.z = 0.0
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://assets/icons/%s.png" % plan)
		pivot.queue_free()
		await get_tree().process_frame
	print("ICONS done")
	get_tree().quit()


## The box around every mesh under a node, as the node is turned now.
func _bounds(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var part := mesh.global_transform * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box
