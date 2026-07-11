extends SceneTree
## Headless smoke test for core domain logic.
## Run: godot --headless -s res://tests/test_core.gd

var failures := 0

func _initialize() -> void:
	test_festival_time()
	test_needs_decay()
	test_multiplier_bounds()
	test_sets_and_zones()
	if failures == 0:
		print("ALL TESTS PASSED")
	else:
		printerr("%d TEST(S) FAILED" % failures)
	quit(1 if failures > 0 else 0)

func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: ", msg)
	else:
		failures += 1
		printerr("  FAIL: ", msg)

func test_festival_time() -> void:
	print("FestivalTime:")
	check(FestivalTime.day(0.0) == 1, "minute 0 is day 1")
	check(FestivalTime.clock_string(0.0) == "11:00", "minute 0 reads 11:00")
	check(FestivalTime.clock_string(60.0) == "12:00", "one hour later reads 12:00")
	check(FestivalTime.clock_string(13.0 * 60.0) == "00:00", "13h later wraps to 00:00")
	check(FestivalTime.day(13.0 * 60.0) == 2, "13h later is Day 2")
	check(FestivalTime.day(24.0 * 60.0) == 2, "24h later still Day 2 (back to 11:00)")
	check(FestivalTime.clock_string(24.0 * 60.0) == "11:00", "24h later reads 11:00")

func test_needs_decay() -> void:
	print("Needs decay:")
	var n := Needs.new()
	check(n.get_value(Needs.Kind.HUNGER) == 100.0, "starts full")
	n.decay(60.0)
	var h := n.get_value(Needs.Kind.HUNGER)
	check(h < 100.0 and h > 80.0, "hunger drops modestly over 1 game-hour (got %.1f)" % h)
	n.decay(100000.0)
	check(n.get_value(Needs.Kind.ENERGY) == 0.0, "decay clamps at zero")

func test_multiplier_bounds() -> void:
	print("Enjoyment multiplier:")
	var full := Needs.new()
	check(absf(full.enjoyment_multiplier() - Needs.MULT_MAX) < 0.001, "full needs give MULT_MAX")
	var empty := Needs.new()
	empty.decay(100000.0)
	check(absf(empty.enjoyment_multiplier() - Needs.MULT_MIN) < 0.001, "empty needs give MULT_MIN")

func test_sets_and_zones() -> void:
	print("Sets & zones:")
	var st := Stage.new("s", "S", Vector2.ZERO)
	var a := Artist.new("A", "metal", 0.9, true, 1.0)
	var fs := FestivalSet.new(a, st, 10.0, 20.0)
	check(not fs.is_active(9.9), "set inactive just before start")
	check(fs.is_active(10.0), "set active at start")
	check(fs.is_active(19.9), "set active just before end")
	check(not fs.is_active(20.0), "set inactive at end")

	check(Audience.zone_at(0.0) == Audience.Zone.FRONT, "stage center is Front")
	check(Audience.zone_at(Audience.MID_RADIUS) == Audience.Zone.MID, "mid radius is Mid")
	check(Audience.zone_at(Audience.BACK_RADIUS + 1.0) == Audience.Zone.NONE, "beyond back is None")
	check(Audience.multiplier(Audience.Zone.FRONT) > Audience.multiplier(Audience.Zone.BACK),
		"Front pays more than Back")

	var lu := Lineup.build_demo()
	check(lu.stages.size() == 3, "demo lineup has 3 stages")
	var headline := lu.active_set_for(lu.stages[0], 10.0)
	check(headline != null and headline.artist.is_favorite, "favorite headlines main stage at 10min")
