extends Node
## Integration test for the Enjoyment tick, run as a real scene so the Clock/Game
## autoload globals are bound normally.
## Run: godot --headless res://tests/test_scoring.tscn

var failures := 0

func _ready() -> void:
	Game.start_new_run(null, 404)
	var main_stage: Stage = Game.lineup.stages[0]
	var opening_set: FestivalSet = Game.lineup.active_set_for(main_stage, 0.0)
	opening_set.end_minute = 2.0

	var player := Node2D.new()
	player.name = "Player"
	add_child(player)
	player.global_position = main_stage.position  # distance 0 -> Front zone

	var enj = load("res://scripts/systems/enjoyment.gd").new()
	enj.name = "Enjoyment"
	enj.player_path = NodePath("../Player")
	add_child(enj)  # _ready resolves the player and connects the clock

	Clock.set_paused(false)
	Clock.set_time_scale(1.0)

	# Five simulated minutes cross the Set's end, so only two attended minutes score.
	Clock.advance(5.0)
	check(Game.current_score() > 0.0, "score accrues in Front zone during the favorite's set")

	var expected := opening_set.artist.affinity \
		* Audience.multiplier(Audience.Zone.FRONT) \
		* Game.needs.enjoyment_multiplier() \
		* 2.0
	check(absf(Game.current_score() - expected) < 0.001,
		"score includes only minutes actually attended (got %.3f, expected %.3f)" % [Game.current_score(), expected])
	check(Game.score_ledger.attended_minutes_for(opening_set) == 2.0,
		"the ledger attributes partial attendance to its Set")
	check(Game.score_ledger.entries[0].zone_multiplier == Audience.multiplier(Audience.Zone.FRONT),
		"the attendance entry explains its Audience Zone multiplier")
	check(Game.score_ledger.total() == Game.current_score(), "ledger total equals the Run score")

	# Leaving every Audience Zone stops accrual immediately.
	var before := Game.current_score()
	player.global_position = main_stage.position + Vector2(5000, 0)
	Clock.advance(5.0)
	check(absf(Game.current_score() - before) < 0.001, "no score when outside every zone")
	var bonus := Game.award_bonus("test bonus", 1.0)
	check(bonus > 0.0 and Game.score_ledger.entries[-1].source_name == "test bonus",
		"named bonuses flow through the same ledger")
	var after_bonus := Game.current_score()
	Game.award_bonus("invalid penalty", -10.0)
	check(Game.current_score() == after_bonus, "the public score API is monotonic")
	check(Game.theoretical_maximum() >= Game.current_score(), "Festival maximum never falls below achieved score")
	check(Game.score_percentage() > 0.0, "score percentage is queryable without presentation code")

	# A faster clock sends the same simulation-minute delta to every listener.
	Game.start_new_run(null, 404)
	main_stage = Game.lineup.stages[0]
	opening_set = Game.lineup.active_set_for(main_stage, 0.0)
	player.global_position = main_stage.position
	Clock.set_time_scale(5.0)
	Clock.advance(1.0)
	var fast_score := Game.current_score()
	Game.start_new_run(null, 404)
	Clock.set_time_scale(1.0)
	Clock.advance(5.0)
	check(absf(Game.current_score() - fast_score) < 0.001,
		"fast-forward applies the same scoring and Needs simulation for equal game time")

	if failures == 0:
		print("ALL SCORING TESTS PASSED")
	else:
		printerr("%d SCORING TEST(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: ", msg)
	else:
		failures += 1
		printerr("  FAIL: ", msg)
