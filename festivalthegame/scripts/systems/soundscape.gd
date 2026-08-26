class_name FestivalSoundscape
extends Node2D
## One stable pair of positional players per Stage; content switches in place.

var settings := AudioSettings.new()
var _catalog: GenreCatalog
var _music_players := {}
var _crowd_players := {}
var _active_sets := {}

func _ready() -> void:
	_catalog = GenreCatalog.load_bundled()
	settings.load()
	Clock.time_advanced.connect(func(_minutes: float) -> void: _sync())
	Clock.run_completed.connect(stop_all)
	build_for_lineup()

func build_for_lineup() -> void:
	for player in _music_players.values():
		(player as AudioStreamPlayer2D).queue_free()
	for player in _crowd_players.values():
		(player as AudioStreamPlayer2D).queue_free()
	_music_players.clear()
	_crowd_players.clear()
	_active_sets.clear()
	if Game.lineup == null:
		return
	for stage in Game.lineup.stages:
		var music := AudioStreamPlayer2D.new()
		music.position = stage.position
		music.max_distance = Audience.BACK_RADIUS
		music.attenuation = 2.2
		music.bus = &"Music"
		add_child(music)
		_music_players[stage.id] = music
		var crowd := AudioStreamPlayer2D.new()
		crowd.position = stage.position
		crowd.max_distance = Audience.BACK_RADIUS * 1.15
		crowd.attenuation = 2.8
		crowd.bus = &"Ambience"
		crowd.stream = load("res://audio/loops/crowd.wav")
		if crowd.stream is AudioStreamWAV:
			(crowd.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		add_child(crowd)
		_crowd_players[stage.id] = crowd
	_sync()

func _process(_delta: float) -> void:
	_sync()

func _sync() -> void:
	if Game.lineup == null:
		return
	for stage in Game.lineup.stages:
		var festival_set := Game.lineup.active_set_for(stage, Clock.total_minutes)
		var music: AudioStreamPlayer2D = _music_players[stage.id]
		var crowd: AudioStreamPlayer2D = _crowd_players[stage.id]
		music.stream_paused = Clock.paused
		crowd.stream_paused = Clock.paused
		if festival_set == _active_sets.get(stage.id):
			continue
		_active_sets[stage.id] = festival_set
		music.stop()
		crowd.stop()
		if festival_set == null or not FestivalTime.is_arena_open(Clock.total_minutes):
			continue
		music.stream = load(GenreSoundMap.path_for(festival_set.artist.genre_id, _catalog))
		if music.stream is AudioStreamWAV:
			(music.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		var offset := fmod(maxf(0.0, Clock.total_minutes - festival_set.start_minute) * 0.23, music.stream.get_length())
		music.play(offset)
		var density := CrowdField.density(Game.lineup, stage.position, Clock.total_minutes)
		crowd.volume_db = linear_to_db(maxf(0.02, festival_set.artist.popularity * density))
		crowd.play(fmod(offset, crowd.stream.get_length()))

func stop_all() -> void:
	for player in _music_players.values():
		(player as AudioStreamPlayer2D).stop()
	for player in _crowd_players.values():
		(player as AudioStreamPlayer2D).stop()

func active_player_count() -> int:
	return _music_players.size() + _crowd_players.size()
