extends SceneTree
## Public domain tests for score accounting and the festival-specific ceiling.

var failures := 0

func _initialize() -> void:
	test_ledger_records_explain_every_point()
	test_theoretical_maximum_selects_best_overlap()
	quit(1 if failures > 0 else 0)

func test_ledger_records_explain_every_point() -> void:
	print("Score ledger:")
	var stage := Stage.new("stage", "Stage", Vector2.ZERO)
	var artist := Artist.new("Artist", "genre", 0.5, false, 0.5)
	var festival_set := FestivalSet.new(artist, stage, 0.0, 10.0)
	var ledger := ScoreLedger.new()
	var first := ledger.record_attendance(festival_set, 3.0, 0.5, 1.15, 0.8)
	var second := ledger.record_attendance(festival_set, 2.0, 0.5, 1.15, 1.0)
	var bonus := ledger.record_bonus("shared experience", 4.0)
	check(first != null and second != null and bonus != null, "attendance and named bonuses create entries")
	check(ledger.attended_minutes_for(festival_set) == 5.0, "late arrival and early departure minutes aggregate per Set")
	check(first == second and first.affinity_multiplier == 0.5 and first.zone_multiplier == 1.15,
		"contiguous attendance for one Set and zone stays compact")
	check(absf(second.needs_multiplier - 0.88) < 0.001,
		"multiplier changes retain the exact weighted multiplier that produced the points")
	check(bonus.source_name == "shared experience" and bonus.attended_minutes == 0.0,
		"bonus entries retain their named source")
	var explained := 0.0
	for entry in ledger.entries:
		explained += entry.points
	check(absf(explained - ledger.total()) < 0.001, "ledger entries always sum to its total")
	var before := ledger.total()
	check(ledger.record_bonus("penalty", -100.0) == null and ledger.total() == before,
		"negative gameplay events cannot subtract points")

func test_theoretical_maximum_selects_best_overlap() -> void:
	print("Theoretical maximum:")
	var first_stage := Stage.new("first", "First", Vector2.ZERO)
	var second_stage := Stage.new("second", "Second", Vector2(1000, 0))
	var ordinary := Artist.new("Ordinary", "genre", 0.5, false, 0.5)
	var favorite := Artist.new("Favorite", "genre", 0.5, true, 0.2)
	var lineup := Lineup.new()
	lineup.stages = [first_stage, second_stage]
	lineup.artists = [ordinary, favorite]
	lineup.sets = [
		FestivalSet.new(ordinary, first_stage, 0.0, 10.0),
		FestivalSet.new(favorite, second_stage, 5.0, 15.0),
	]
	var expected := (5.0 * 0.5 + 10.0 * 1.0) \
		* Audience.multiplier(Audience.Zone.FRONT) * Needs.MULT_MAX
	var first_calculation := TheoreticalMaximum.calculate(lineup)
	check(absf(first_calculation - expected) < 0.001,
		"ceiling selects the best active Set and gives Favorites full affinity")
	check(TheoreticalMaximum.calculate(lineup) == first_calculation,
		"the Festival ceiling is deterministic")

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
