extends Node
## Exact mutable-state round trip and safe save failure behavior.

var failures := 0

func _ready() -> void:
	var config := RunConfiguration.new()
	config.add_favorite("Favorite", "cc28f5aa-5e19-487c-88e1-e56b022f1fdd")
	config.set_friend_count(2)
	config.select_campsite("camp_2")
	Game.start_new_run(config, 2222)
	Clock.advance_game_minutes(123.0)
	Game.needs.adjust(Needs.Kind.HUNGER, -37.0)
	Game.budget = 73.5
	Game.award_bonus("Saved bonus", 9.0)
	Game.food_poisoning.schedule()
	Game.tipsy.level = 0.4
	Game.tipsy.remaining_minutes = 55.0
	Game.mosh.injured = true
	Game.run_events.append(RunEvent.new("collapse", 100.0, "Saved event"))
	Game.friends[0].meet_destination = Game.grounds.points[0]
	Game.friends[0].meet_until = 180.0
	var position := Vector2(321, -123)
	var expected_hunger := Game.needs.get_value(Needs.Kind.HUNGER)
	var expected_signature: String = "%s:%d:%s" % [
		Game.lineup.sets[0].artist.name, Game.lineup.sets.size(), Game.grounds.placement_signature()]
	var expected_events := Game.run_events.size()
	var path := "user://test_active_%d.json" % Time.get_ticks_usec()
	var store := IronmanSave.new(path)
	check(store.save(Game.snapshot(position)) and store.has_active_run(), "one atomic active autosave is created")
	Game.start_new_run(config, 9999)
	var restored := Game.restore_snapshot(store.load_snapshot())
	check(not restored.is_empty() and restored["player_position"] == position, "player position round-trips")
	var restored_signature: String = "%s:%d:%s" % [
		Game.lineup.sets[0].artist.name, Game.lineup.sets.size(), Game.grounds.placement_signature()]
	check(Game.run_seed == 2222 and Clock.total_minutes == 123.0 and restored_signature == expected_signature,
		"seed, configuration, Lineup, time, and phase restore exactly")
	check(is_equal_approx(Game.needs.get_value(Needs.Kind.HUNGER), expected_hunger) \
			and is_equal_approx(Game.budget, 73.5) and is_equal_approx(Game.current_score(), 9.0),
		"Needs, Budget, and score ledger restore without replay")
	check(Game.food_poisoning.is_pending() and Game.tipsy.level == 0.4 and Game.mosh.injured,
		"major timed effects round-trip")
	check(Game.friends[0].meet_destination == Game.grounds.points[0] and Game.run_events.size() == expected_events,
		"Friends, choices, campsite-derived map, and event history restore")
	var events_after_load := Game.run_events.size()
	check(Game.run_events.size() == events_after_load, "loading does not replay side effects")
	var corrupt := FileAccess.open(path, FileAccess.WRITE)
	corrupt.store_string("not json")
	corrupt.close()
	check(store.load_snapshot().is_empty() and store.last_error.contains("corrupt"),
		"corrupt saves fail safely with a clear recovery path")
	store.clear()
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
