extends SceneTree
## Public-seam tests for deliberate Schedule Conflicts and planner data.

var failures := 0
var catalog := GenreCatalog.load_bundled()
var graph := GenreGraph.load_bundled()

func _initialize() -> void:
	test_multiple_favorites_conflict()
	test_single_favorite_conflicts_with_desirable_set()
	test_day_schedule_is_sorted_and_complete()
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)

func test_multiple_favorites_conflict() -> void:
	print("Favorite Schedule Conflicts:")
	var config := RunConfiguration.new()
	config.add_favorite("Metal Favorite", "cc28f5aa-5e19-487c-88e1-e56b022f1fdd")
	config.add_favorite("Pop Favorite", "911c7bbb-172d-4df8-9478-dbff4296e791")
	for seed_value in range(1, 26):
		var lineup := FestivalGenerator.generate(config, seed_value, catalog, graph)
		var conflicts := SchedulePlanner.conflicts(lineup)
		if not conflicts.any(func(conflict: ScheduleConflict) -> bool:
			return conflict.first.artist.is_favorite and conflict.second.artist.is_favorite):
			check(false, "two configured Favorite Artists overlap across generation seeds")
			return
	check(true, "two configured Favorite Artists overlap across generation seeds")

func test_single_favorite_conflicts_with_desirable_set() -> void:
	print("Single-favorite Schedule Conflict:")
	var config := RunConfiguration.new()
	config.add_favorite("Only Favorite", "cc28f5aa-5e19-487c-88e1-e56b022f1fdd")
	for seed_value in range(1, 26):
		var lineup := FestivalGenerator.generate(config, seed_value, catalog, graph)
		var conflicts := SchedulePlanner.conflicts(lineup)
		if not conflicts.any(func(conflict: ScheduleConflict) -> bool:
			var other := conflict.second.artist if conflict.first.artist.is_favorite else conflict.first.artist
			return (conflict.first.artist.is_favorite or conflict.second.artist.is_favorite) and other.affinity >= 0.80):
			check(false, "one Favorite Artist overlaps a desirable Set across generation seeds")
			return
	check(true, "one Favorite Artist overlaps a desirable Set across generation seeds")

func test_day_schedule_is_sorted_and_complete() -> void:
	print("Schedule planner data:")
	var config := RunConfiguration.new()
	config.add_favorite("Favorite", "cc28f5aa-5e19-487c-88e1-e56b022f1fdd")
	var lineup := FestivalGenerator.generate(config, 101, catalog, graph)
	var total := 0
	for day in range(1, FestivalGenerator.DAY_COUNT + 1):
		var day_sets := SchedulePlanner.sets_for_day(lineup, day)
		total += day_sets.size()
		for index in range(1, day_sets.size()):
			if day_sets[index].start_minute < day_sets[index - 1].start_minute:
				check(false, "each Festival Day is sorted by Set start time")
				return
	check(total == lineup.sets.size(), "browsing all Festival Days includes every Set exactly once")
	check(SchedulePlanner.conflicted_sets(lineup).size() >= 2, "planner can mark both sides of a conflict")
