class_name UI
## Small helpers shared by every screen: colours, labels, buttons, sprites.

const INK := Color("14121c")
const PANEL := Color("231f33")
const PANEL_LIGHT := Color("342e4a")
const EDGE := Color("4b4368")
const TEXT := Color("ece8f5")
const DIM := Color("9a93b3")
const GOLD := Color("ffc94a")
const GOOD := Color("7be08a")
const BAD := Color("ff6b6b")

const TILES := preload("res://assets/tiles/tiny_dungeon.png")
const WEAPON_SHADER := preload("res://assets/weapon.gdshader")
const TILE_SIZE := 16
const TILE_COLUMNS := 12


static func box(color: Color, border: Color = EDGE, width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_content_margin_all(6)
	return style


static func label(text: String, size := 16, color: Color = TEXT) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	return node


static func button(text: String, size := 16) -> Button:
	var node := Button.new()
	node.text = text
	node.focus_mode = Control.FOCUS_NONE
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", TEXT)
	node.add_theme_color_override("font_disabled_color", Color(DIM, 0.6))
	node.add_theme_stylebox_override("normal", box(PANEL_LIGHT))
	node.add_theme_stylebox_override("hover", box(PANEL_LIGHT.lightened(0.08)))
	node.add_theme_stylebox_override("pressed", box(EDGE, GOLD))
	node.add_theme_stylebox_override("disabled", box(PANEL, PANEL_LIGHT))
	node.pressed.connect(func(): Sfx.play("metalClick", 1.0, -8.0))
	return node


static func panel(color: Color = PANEL, border: Color = EDGE) -> PanelContainer:
	var node := PanelContainer.new()
	node.add_theme_stylebox_override("panel", box(color, border))
	return node


## Marks a button as the selected one of its group.
static func highlight(node: Button, on: bool, color: Color = GOLD) -> void:
	node.add_theme_stylebox_override("normal", box(EDGE if on else PANEL_LIGHT, color if on else EDGE))


static func tile_texture(index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = TILES
	@warning_ignore("integer_division")
	atlas.region = Rect2(index % TILE_COLUMNS * TILE_SIZE, index / TILE_COLUMNS * TILE_SIZE, TILE_SIZE, TILE_SIZE)
	return atlas


static func tile_sprite(index: int, zoom := 4.0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tile_texture(index)
	sprite.scale = Vector2(zoom, zoom)
	return sprite


static func weapon_material(material: String, rarity: int) -> ShaderMaterial:
	var shader := ShaderMaterial.new()
	shader.shader = WEAPON_SHADER
	var mat: Dictionary = Catalog.MATERIALS[material]
	shader.set_shader_parameter("metal_dark", Vector3(mat.dark.r, mat.dark.g, mat.dark.b))
	shader.set_shader_parameter("metal_light", Vector3(mat.light.r, mat.light.g, mat.light.b))
	var outline := Color(0, 0, 0, 0)
	if rarity > 0:
		outline = Catalog.RARITIES[rarity].color
	shader.set_shader_parameter("outline", outline)
	return shader


static func weapon_texture(plan: String) -> Texture2D:
	return load("res://assets/weapons/%s.png" % Catalog.PLANS[plan].sprite)


## A weapon picture for menus (a Control), 32 px times zoom.
static func weapon_icon(plan: String, material: String, rarity: int, zoom := 2) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = weapon_texture(plan)
	icon.material = weapon_material(material, rarity)
	icon.custom_minimum_size = Vector2(32, 32) * zoom
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


## A small coloured ingot followed by a number, for material counts.
static func material_chip(material: String, count: int, size := 16) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	var ingot := ColorRect.new()
	ingot.color = Catalog.MATERIALS[material].light.lerp(Catalog.MATERIALS[material].dark, 0.35)
	ingot.custom_minimum_size = Vector2(10, 10)
	ingot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ingot)
	row.add_child(label(str(count), size, TEXT if count > 0 else DIM))
	return row


static func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


## A number or a word that rises and fades above a point.
static func float_text(parent: Node, text: String, at: Vector2, color: Color, size := 16) -> void:
	var node := label(text, size, color)
	node.add_theme_color_override("font_outline_color", INK)
	node.add_theme_constant_override("outline_size", 4)
	node.position = at - Vector2(size * text.length() * 0.3, size)
	node.z_index = 20
	parent.add_child(node)
	var tween := node.create_tween()
	tween.tween_property(node, "position:y", node.position.y - 36, 0.7)
	tween.parallel().tween_property(node, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tween.tween_callback(node.queue_free)


static func sparks(parent: Node, at: Vector2, color: Color, amount := 14) -> void:
	var burst := CPUParticles2D.new()
	burst.position = at
	burst.amount = amount
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.lifetime = 0.5
	burst.direction = Vector2(0, -1)
	burst.spread = 80.0
	burst.initial_velocity_min = 60.0
	burst.initial_velocity_max = 170.0
	burst.gravity = Vector2(0, 420)
	burst.scale_amount_min = 2.0
	burst.scale_amount_max = 3.0
	burst.color = color
	burst.z_index = 10
	burst.emitting = true
	parent.add_child(burst)
	burst.finished.connect(burst.queue_free)
