extends Node

var failures := 0

func _ready() -> void:
	var catalog := GenreCatalog.load_bundled()
	var genre := catalog.all_entries()[0]
	var first := GenreSoundMap.path_for(genre.id, catalog)
	check(first == GenreSoundMap.path_for(genre.id, catalog), "Genre-to-loop mapping is deterministic")
	check(GenreSoundMap.all_assets_available(), "all mapped music and crowd assets are bundled offline")
	check(AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_index("Ambience") >= 0 \
			and AudioServer.get_bus_index("Effects") >= 0, "separate mixer buses are configured")
	var path := "user://test_audio_%d.cfg" % Time.get_ticks_usec()
	var settings := AudioSettings.new(path)
	settings.set_level("Music", 0.31)
	settings.set_level("Ambience", 0.42)
	settings.set_level("Effects", 0.53)
	check(settings.save(), "volume controls persist locally")
	var loaded := AudioSettings.new(path)
	check(loaded.load() and is_equal_approx(loaded.levels["Music"], 0.31) \
			and is_equal_approx(loaded.levels["Effects"], 0.53), "all bus levels restore offline")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var config := RunConfiguration.new()
	config.add_favorite("Favorite", genre.id)
	config.select_campsite("camp_1")
	Game.start_new_run(config, 2424)
	var soundscape := FestivalSoundscape.new()
	add_child(soundscape)
	soundscape.build_for_lineup()
	check(soundscape.active_player_count() == Game.lineup.stages.size() * 2,
		"simultaneous Stages have one stable music and crowd player each")
	Clock.paused = true
	soundscape._process(0.0)
	check(soundscape.active_player_count() == Game.lineup.stages.size() * 2,
		"pause and resync never duplicate playback nodes")
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
