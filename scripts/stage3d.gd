class_name Stage3D
extends Node2D
## A 3D scene shown as a 2D picture. The camera never moves, so every point of
## the picture is one point of the ground: the 2D code places things on the
## picture, and their models follow in 3D (see ground() and at_depth()).

## How many pixels are drawn for one unit of the game's 360 x 640 screen.
const DETAIL := 3.0

var size := Vector2(360, 400)
## Everything of the scene; scenery holds the decor, replaced with the zone.
var world: Node3D
var scenery: Node3D
var environment: Environment

var _camera: Camera3D
var _viewport: SubViewport
var _sun: DirectionalLight3D
var _rim: DirectionalLight3D


## picture: the size on screen; eye: where the camera is; pitch: how far it
## looks down, in degrees; fov: how wide it sees, in degrees.
static func make(picture: Vector2, eye: Vector3, pitch: float, fov: float) -> Stage3D:
	var stage := Stage3D.new()
	stage.size = picture
	stage._build(eye, pitch, fov)
	return stage


func _build(eye: Vector3, pitch: float, fov: float) -> void:
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

	_camera = Camera3D.new()
	_camera.fov = fov
	_camera.position = eye
	_camera.rotation_degrees.x = -pitch
	_camera.far = 120.0
	world.add_child(_camera)

	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	var holder := WorldEnvironment.new()
	holder.environment = environment
	world.add_child(holder)
	_sun = DirectionalLight3D.new()
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 40.0
	world.add_child(_sun)
	# A light from behind, for a bright edge around the characters.
	_rim = DirectionalLight3D.new()
	_rim.rotation_degrees = Vector3(-20, 40, 0)
	world.add_child(_rim)
	light(Color(0.55, 0.65, 0.85), 0.4, Color(1.0, 0.86, 0.66), 0.95, Color("9fb8c9"), 0.012)

	var picture := Sprite2D.new()
	picture.texture = _viewport.get_texture()
	picture.centered = false
	picture.scale = Vector2.ONE / DETAIL
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(picture)


## The mood of the scene: the light from everywhere, the sun, the sky and the haze.
func light(ambient: Color, ambient_power: float, sun: Color, sun_power: float, sky: Color, haze: float, sun_turn := -140.0) -> void:
	environment.ambient_light_color = ambient
	environment.ambient_light_energy = ambient_power
	environment.background_color = sky
	environment.fog_light_color = sky
	environment.fog_density = haze * 0.22
	_sun.light_color = sun
	_sun.light_energy = sun_power
	_sun.rotation_degrees = Vector3(-38, sun_turn, 0)
	_rim.light_color = ambient.lightened(0.2)
	_rim.light_energy = 0.45


## The direction seen at a point of the picture.
func _ray(point: Vector2) -> Vector3:
	var half := tan(deg_to_rad(_camera.fov) / 2.0)
	var across := (point.x / size.x * 2.0 - 1.0) * half * size.x / size.y
	var up := (1.0 - point.y / size.y * 2.0) * half
	return _camera.basis * Vector3(across, up, -1.0)


## The point of the ground shown at a point of the picture.
func ground(point: Vector2) -> Vector3:
	var ray := _ray(point)
	return _camera.position + ray * (-_camera.position.y / ray.y)


## The point shown at a point of the picture, at a given distance from the front.
func at_depth(point: Vector2, depth: float) -> Vector3:
	var ray := _ray(point)
	return _camera.position + ray * ((depth - _camera.position.z) / ray.z)


func clear_scenery() -> void:
	for child in scenery.get_children():
		child.queue_free()
