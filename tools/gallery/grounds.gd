extends Node
## Draws the repeating pictures of the grounds into assets/quaternius/ground.
## godot --headless --path . res://tools/gallery/grounds.tscn -- --test

const SIZE := 512
## name: the colours from the lowest to the highest part of the noise.
const GROUNDS := {
	"grass": ["26381c", "354a24", "4d4229", "4f5a2c"],
	"sand": ["5a4229", "70522f", "82643b", "684c2e"],
	"cave": ["24262f", "30323e", "3a3a45", "2c3438"],
}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/quaternius/ground")
	for id in GROUNDS:
		var broad := FastNoiseLite.new()
		broad.seed = id.hash()
		broad.frequency = 0.012
		var fine := FastNoiseLite.new()
		fine.seed = id.hash() + 1
		fine.frequency = 0.12
		var a := broad.get_seamless_image(SIZE, SIZE)
		var b := fine.get_seamless_image(SIZE, SIZE)
		var picture := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
		var colors: Array = GROUNDS[id]
		for y in SIZE:
			for x in SIZE:
				var level := clampf(a.get_pixel(x, y).r * 0.8 + b.get_pixel(x, y).r * 0.2, 0.0, 0.999) * (colors.size() - 1)
				var from := Color(colors[int(level)])
				var to := Color(colors[int(level) + 1])
				picture.set_pixel(x, y, from.lerp(to, level - int(level)) * (0.9 + b.get_pixel((x * 3) % SIZE, (y * 3) % SIZE).r * 0.2))
		picture.save_png("res://assets/quaternius/ground/%s.png" % id)
	# Stone slabs: a grid of joints over a little noise.
	var grain := FastNoiseLite.new()
	grain.frequency = 0.05
	var noise := grain.get_seamless_image(SIZE, SIZE)
	var slabs := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var cell := Vector2i(x / 128, y / 128)
			var shade := 0.3 + 0.018 * float((cell.x * 7 + cell.y * 13) % 5) + noise.get_pixel(x, y).r * 0.08
			if x % 128 < 3 or y % 128 < 3:
				shade *= 0.5
			slabs.set_pixel(x, y, Color(shade * 0.95, shade * 0.92, shade * 1.05))
	slabs.save_png("res://assets/quaternius/ground/stone.png")
	print("GROUNDS done")
	get_tree().quit()
