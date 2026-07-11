extends Node
## Integration test for the Enjoyment tick, run as a real scene so the Clock/Game
## autoload globals are bound normally.
## Run: godot --headless res://tests/test_scoring.tscn

var failures := 0

func _ready() -> void:
	var main_stage: Stage = Game.lineup.stages[0]

	var player := Node2D.new()
	player.name = "Player"
	add_child(player)
	player.global_position = main_stage.position  # distance 0 -> Front zone

	var enj = load("res://scripts/systems/enjoyment.gd").new()
	enj.name = "Enjoyment"
	enj.player_path = NodePath("../Player")
	add_child(enj)  # _ready resolves the player and connects the clock

	Clock.total_minutes = 0.0       # favorite headlines main stage 0..90
	Game.enjoyment_score = 0.0

	# Attend 5 game-minutes from the Front zone.
	enj._on_time_advanced(5.0)
	check(Game.enjoyment_score > 0.0, "score accrues in Front zone during the favorite's set")

	var expected := 1.0 \
		* Audience.multiplier(Audience.Zone.FRONT) \
		* Game.needs.enjoyment_multiplier() \
		* 5.0
	check(absf(Game.enjoyment_score - expected) < 0.001,
		"score matches the equation (got %.3f, expected %.3f)" % [Game.enjoyment_score, expected])

	# Walk far away: no active zone, no accrual.
	var before := Game.enjoyment_score
	player.global_position = main_stage.position + Vector2(5000, 0)
	enj._on_time_advanced(5.0)
	check(absf(Game.enjoyment_score - before) < 0.001, "no score when outside every zone")

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
