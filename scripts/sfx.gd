extends Node
## Plays the game's sounds by what happens, not by file: Sfx.play("hammer").
## To change a sound, change its line here: [file in assets/audio, volume in dB].

const SOUNDS := {
	"click": ["select_002", -10.0],
	"switch": ["select_001", -6.0],
	"hammer": ["drop_002", -2.0],
	"hammer_perfect": ["glass_006", -10.0],
	"quench": ["maximize_006", -4.0],
	"gesture_done": ["confirmation_001", -8.0],
	"hit": ["drop_001", -5.0],
	"skill": ["glass_003", -9.0],
	"hurt": ["bong_001", -3.0],
	"loot": ["confirmation_004", -8.0],
	"plan": ["confirmation_002", -5.0],
	"descend": ["question_004", -6.0],
	"leave": ["jingles_PIZZA02", -6.0],
	"defeat": ["question_002", -4.0],
	"melt": ["back_002", -6.0],
	# One for each rarity, from normal to mythic.
	"rarity_0": ["confirmation_001", -6.0],
	"rarity_1": ["confirmation_004", -6.0],
	"rarity_2": ["jingles_PIZZA05", -5.0],
	"rarity_3": ["jingles_PIZZA04", -5.0],
	"rarity_4": ["jingles_STEEL08", -6.0],
	"rarity_5": ["jingles_STEEL01", -6.0],
}

var _players: Array[AudioStreamPlayer] = []
var _streams := {}
var _next := 0


func _ready() -> void:
	for i in 6:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play(sound: String, pitch := 1.0) -> void:
	var line: Array = SOUNDS[sound]
	if not _streams.has(line[0]):
		_streams[line[0]] = load("res://assets/audio/%s.ogg" % line[0])
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _streams[line[0]]
	player.pitch_scale = pitch
	player.volume_db = line[1]
	player.play()
