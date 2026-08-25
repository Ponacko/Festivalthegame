extends SceneTree
## Public-seam tests for seeded procedural Festival generation.

var failures := 0
var catalog: GenreCatalog
var graph: GenreGraph
var configuration: RunConfiguration

func _initialize() -> void:
	catalog = GenreCatalog.load_bundled()
	graph = GenreGraph.load_bundled()
	configuration = RunConfiguration.new()
	configuration.add_favorite("Iron Example", "cc28f5aa-5e19-487c-88e1-e56b022f1fdd")
	configuration.add_favorite("Pop Example", "911c7bbb-172d-4df8-9478-dbff4296e791")
	configuration.add_favorite("Jazz Example", "a715278f-1580-409f-8078-4ffbc800e08b")
	test_reproducible_festival()
	test_taste_bias_and_variety()
	test_structural_invariants_across_seeds()
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)

func test_reproducible_festival() -> void:
	print("Festival reproducibility:")
	var first := FestivalGenerator.generate(configuration, 424242, catalog, graph)
	var second := FestivalGenerator.generate(configuration, 424242, catalog, graph)
	check(signature(first) == signature(second), "the same seed and configuration reproduce the Festival")
	check(first.artists.any(func(artist: Artist) -> bool: return artist.name == "Iron Example"),
		"the first Favorite Artist is guaranteed")
	check(first.artists.any(func(artist: Artist) -> bool: return artist.name == "Pop Example"),
		"the second Favorite Artist is guaranteed")
	check(first.artists.any(func(artist: Artist) -> bool: return artist.name == "Jazz Example"),
		"the third Favorite Artist is guaranteed")

func test_taste_bias_and_variety() -> void:
	print("Taste bias:")
	var lineup := FestivalGenerator.generate(configuration, 17, catalog, graph)
	var near_count := 0
	var floor_count := 0
	var genres := {}
	for artist in lineup.artists:
		genres[artist.genre_id] = true
		if artist.affinity > ArtistAffinity.MIN_AFFINITY + 0.001:
			near_count += 1
		else:
			floor_count += 1
	check(near_count >= int(lineup.artists.size() * 0.65), "most Artists align with the player's tastes")
	check(floor_count >= int(lineup.artists.size() * 0.08), "the Lineup retains floor-affinity variety")
	check(genres.size() >= 20, "the biased Lineup still spans many Genres")

func test_structural_invariants_across_seeds() -> void:
	print("Generator invariants:")
	var all_valid := true
	for seed in range(1, 26):
		var lineup := FestivalGenerator.generate(configuration, seed, catalog, graph)
		if not valid_structure(lineup):
			all_valid = false
			break
	check(all_valid, "25 representative seeds satisfy every structural invariant")

func valid_structure(lineup: Lineup) -> bool:
	if lineup.stages.size() != 4 or lineup.artists.size() < 100 or lineup.artists.size() > 120:
		return false
	var size_counts := {Stage.Size.MAIN: 0, Stage.Size.MID: 0, Stage.Size.SMALL: 0}
	for stage in lineup.stages:
		size_counts[stage.size] += 1
	if size_counts != {Stage.Size.MAIN: 1, Stage.Size.MID: 2, Stage.Size.SMALL: 1}:
		return false
	if lineup.sets.size() != lineup.artists.size():
		return false
	var names := {}
	var artists_seen := {}
	for festival_set in lineup.sets:
		var duration := festival_set.end_minute - festival_set.start_minute
		if duration not in [45.0, 60.0, 75.0]:
			return false
		if not festival_set.stage.accepts_popularity(festival_set.artist.popularity):
			return false
		if artists_seen.has(festival_set.artist):
			return false
		artists_seen[festival_set.artist] = true
		names[festival_set.artist.name] = true
		var day_offset := fmod(festival_set.start_minute, FestivalTime.MINUTES_PER_DAY)
		if day_offset < 0.0 or day_offset + duration > FestivalGenerator.ARENA_MINUTES:
			return false
	if names.size() != lineup.artists.size():
		return false
	for stage in lineup.stages:
		for day_index in range(FestivalGenerator.DAY_COUNT):
			var day_sets: Array[FestivalSet] = []
			for festival_set in lineup.sets:
				if festival_set.stage == stage and int(festival_set.start_minute / FestivalTime.MINUTES_PER_DAY) == day_index:
					day_sets.append(festival_set)
			day_sets.sort_custom(func(a: FestivalSet, b: FestivalSet) -> bool: return a.start_minute < b.start_minute)
			for index in range(1, day_sets.size()):
				if day_sets[index].start_minute - day_sets[index - 1].end_minute < FestivalGenerator.MIN_CHANGEOVER:
					return false
	return true

func signature(lineup: Lineup) -> String:
	var parts := PackedStringArray()
	for festival_set in lineup.sets:
		parts.append("%s|%s|%s|%.0f|%.0f|%.3f" % [
			festival_set.artist.name,
			festival_set.artist.genre_id,
			festival_set.stage.id,
			festival_set.start_minute,
			festival_set.end_minute,
			festival_set.artist.popularity,
		])
	return "\n".join(parts)
