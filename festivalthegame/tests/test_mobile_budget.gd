extends Node
## Deterministic profiled-equivalent mobile budget and release-content audit.

var failures := 0

func _ready() -> void:
	var config := RunConfiguration.new()
	var genres := GenreCatalog.load_bundled().all_entries()
	for index in range(10):
		config.add_favorite("Favorite %d" % index, genres[index].id)
	config.set_friend_count(4)
	config.select_campsite("camp_3")
	var started := Time.get_ticks_usec()
	Game.start_new_run(config, 2525)
	var generation_ms := (Time.get_ticks_usec() - started) / 1000.0
	var memory_mib := Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	check(generation_ms < 15000.0, "maximum-Friends cold generation stays below 15 s (%.1f ms)" % generation_ms)
	check(memory_mib < 256.0, "profiled static memory stays below 256 MiB (%.1f MiB)" % memory_mib)
	check(Game.friends.size() == 4 and Game.lineup.artists.size() >= 100,
		"profile covers maximum Friends and a full generated Lineup")
	var frame_started := Time.get_ticks_usec()
	for sample in range(600):
		var minute := fmod(float(sample) * 3.7, FestivalTime.run_end_minute())
		for stage in Game.lineup.stages:
			Game.lineup.active_set_for(stage, minute)
			CrowdField.density(Game.lineup, stage.position, minute)
		for friend in Game.friends:
			friend.destination_position_at(minute, Game.grounds)
	var average_frame_ms := (Time.get_ticks_usec() - frame_started) / 1000.0 / 600.0
	check(average_frame_ms <= 16.7, "busy simulation preparation stays within 16.7 ms (%.3f ms average)" % average_frame_ms)
	check(GenreSoundMap.all_assets_available() and FileAccess.file_exists("res://data/musicbrainz_genres.json"),
		"release taxonomy, procedural data, art, and audio are offline")
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	check(presets.contains("platform=\"Android\"") and presets.contains("platform=\"iOS\"") \
			and presets.contains("permissions/internet=false"),
		"Android/iOS presets and offline permission policy are versioned")
	var runtime_scripts := ""
	for path in _runtime_script_paths("res://scripts"):
		runtime_scripts += FileAccess.get_file_as_string(path)
	check(not runtime_scripts.contains("HTTPRequest.new") and not runtime_scripts.contains("HTTPClient.new"),
		"packaged runtime has no network client calls")
	get_tree().quit(1 if failures > 0 else 0)

func _runtime_script_paths(root: String) -> PackedStringArray:
	var result := PackedStringArray()
	var directory := DirAccess.open(root)
	if directory == null:
		return result
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		var path := "%s/%s" % [root, name]
		if directory.current_is_dir():
			result.append_array(_runtime_script_paths(path))
		elif name.ends_with(".gd"):
			result.append(path)
		name = directory.get_next()
	directory.list_dir_end()
	return result

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
