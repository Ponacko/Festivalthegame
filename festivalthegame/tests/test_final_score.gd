extends Node
## Finalization, war stories, and deterministic offline high scores.

var failures := 0

func _ready() -> void:
	var ledger := ScoreLedger.new()
	var stage := Stage.new("stage", "Main", Vector2.ZERO)
	var festival_set := FestivalSet.new(Artist.new("Final Artist", "genre", 1.0), stage, 0.0, 60.0)
	ledger.record_attendance(festival_set, 20.0, 1.0, 1.0, 1.0)
	ledger.record_bonus("Mosh Pit — Final Artist", 5.0)
	var events: Array[RunEvent] = [RunEvent.new("collapse", 20.0, "Energy"), RunEvent.new("purchase", 30.0, "Food")]
	var result := FinalResult.build(77, "2 friends • Camp", ledger, 50.0, events, 1234)
	check(is_equal_approx(result.total_score, 25.0) and is_equal_approx(result.percentage, 50.0),
		"final score and theoretical percentage are exact")
	check(result.breakdown_total() == result.total_score and result.breakdown_text().contains("Mosh Pit"),
		"per-Set and named bonus breakdown totals explain the score")
	check(result.war_stories.size() == 1 and result.war_stories[0].contains("Energy"),
		"notable disasters become war stories without score deductions")

	var path := "user://test_high_scores_%d.json" % Time.get_ticks_usec()
	var store := HighScoreStore.new(path, 3)
	store.insert(FinalResult.build(3, "A", ledger, 100.0, [], 300))
	store.insert(FinalResult.build(1, "B", ledger, 50.0, [], 100))
	store.insert(FinalResult.build(2, "C", ledger, 50.0, [], 200))
	store.insert(FinalResult.build(4, "D", ScoreLedger.new(), 50.0, [], 400))
	check(store.entries.size() == 3, "high-score table enforces bounded retention")
	check(store.entries[0]["percentage"] >= store.entries[1]["percentage"], "high scores sort best-first")
	check(store.entries[0]["run_seed"] == 1 and store.entries[1]["run_seed"] == 2,
		"ties sort deterministically by Run metadata")
	var reloaded := HighScoreStore.new(path, 3)
	reloaded.load()
	check(reloaded.entries.size() == 3 and reloaded.entries[0]["run_seed"] == 1,
		"local high scores persist and reload offline")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	var config := RunConfiguration.new()
	config.add_favorite("Favorite", "cc28f5aa-5e19-487c-88e1-e56b022f1fdd")
	config.select_campsite("camp_1")
	Game.start_new_run(config, 2121)
	Clock.advance_game_minutes(FestivalTime.run_end_minute())
	check(Game.final_result != null and Game.run_status == Game.RunStatus.COMPLETE and Clock.is_complete(),
		"Day 3 finalizes once and prevents further gameplay time")
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
