class_name Stage3D
extends Node2D
## A 3D scene shown as a 2D picture. It is seen from above at a fixed angle and
## without perspective, so every point of the picture is one point of the ground:
## the 2D code places things on the picture, and their models follow in 3D.

## How many pixels are drawn for one unit of the game's 360 x 640 screen.
const DETAIL := 3.0
const TILT := deg_to_rad(30.0)
const CAMERA_AWAY := 25.0
## All the lights are dimmed by this, so that pale things do not turn white.
const EXPOSURE := 0.78

var size := Vector2(360, 400)
## How many screen units one metre of the scene takes.
var unit := 40.0
## Everything of the scene; scenery holds the decor, replaced with the zone.
var world: Node3D
var scenery: Node3D

var _viewport: SubViewport
var _environment: Environment
var _sun: DirectionalLight3D


static func make(picture: Vector2, metre := 40.0) -> Stage3D:
	var stage := Stage3D.new()
	stage.size = picture
	stage.unit = metre
	stage._build()
	return stage


func _build() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(size * DETAIL)
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	world = Node3D.new()
	_viewport.add_child(world)
	scenery = Node3D.new()
	world.add_child(scenery)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = size.y / unit
	camera.rotation.x = -TILT
	camera.position = Vector3(0, sin(TILT), cos(TILT)) * CAMERA_AWAY
	camera.far = 120.0
	world.add_child(camera)

	_environment = Environment.new()
	_environment.background_mode = Environment.BG_COLOR
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var holder := WorldEnvironment.new()
	holder.environment = _environment
	world.add_child(holder)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-52, -32, 0)
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 60.0
	world.add_child(_sun)
	light(Color(0.6, 0.65, 0.85), 0.45, Color(1.0, 0.94, 0.82), 0.75, Color("14121c"))

	var picture := Sprite2D.new()
	picture.texture = _viewport.get_texture()
	picture.centered = false
	picture.scale = Vector2.ONE / DETAIL
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(picture)


## The mood of the scene: the light from everywhere, the sun, and the far colour.
func light(ambient: Color, ambient_power: float, sun: Color, sun_power: float, sky: Color) -> void:
	_environment.ambient_light_color = ambient
	_environment.ambient_light_energy = ambient_power * EXPOSURE
	_environment.background_color = sky
	_sun.light_color = sun
	_sun.light_energy = sun_power * EXPOSURE


## The point of the ground shown at a point of the picture.
func ground(point: Vector2) -> Vector3:
	return Vector3((point.x - size.x / 2.0) / unit, 0.0, (point.y - size.y / 2.0) / (unit * sin(TILT)))


## The point shown at a point of the picture, at a given distance from the front.
func at_depth(point: Vector2, depth: float) -> Vector3:
	var height := (depth * sin(TILT) - (point.y - size.y / 2.0) / unit) / cos(TILT)
	return Vector3((point.x - size.x / 2.0) / unit, height, depth)


func clear_scenery() -> void:
	for child in scenery.get_children():
		child.queue_free()
