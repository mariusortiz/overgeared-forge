extends Node
## Plays the short sounds of assets/audio by name.

var _players: Array[AudioStreamPlayer] = []
var _streams := {}
var _next := 0


func _ready() -> void:
	for i in 6:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play(sound: String, pitch := 1.0, volume_db := 0.0) -> void:
	if not _streams.has(sound):
		_streams[sound] = load("res://assets/audio/%s.ogg" % sound)
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _streams[sound]
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()
