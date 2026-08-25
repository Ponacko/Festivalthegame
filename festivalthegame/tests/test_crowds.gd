extends SceneTree
## Public domain tests for the crowd-density movement field.

var failures := 0

func _initialize() -> void:
	var stage := Stage.new("stage", "Stage", Vector2.ZERO)
	var quiet := Artist.new("Quiet", "genre", 0.2, false, 0.5)
	var headline := Artist.new("Headline", "genre", 1.0, false, 0.5)
	var lineup := Lineup.new()
	lineup.stages = [stage]
	lineup.artists = [quiet, headline]
	lineup.sets = [
		FestivalSet.new(quiet, stage, 0.0, 10.0),
		FestivalSet.new(headline, stage, 20.0, 30.0),
	]

	var quiet_front := CrowdField.density(lineup, stage.position, 5.0)
	var headline_front := CrowdField.density(lineup, stage.position, 25.0)
	check(headline_front > quiet_front, "crowd density scales with active Artist popularity")
	var front := CrowdField.density(lineup, stage.position, 25.0)
	var mid := CrowdField.density(lineup, stage.position + Vector2(Audience.MID_RADIUS, 0), 25.0)
	var back := CrowdField.density(lineup, stage.position + Vector2(Audience.BACK_RADIUS, 0), 25.0)
	check(front > mid and mid > back and back > 0.0, "Front, Mid, and Back have progressively different density")
	check(CrowdField.speed_multiplier(lineup, stage.position, 25.0) == 0.5,
		"peak crowd pressure is approximately a two-times slowdown")
	check(CrowdField.speed_multiplier(lineup, stage.position, 25.0) > 0.0,
		"crowds can never stop movement")
	check(CrowdField.density(lineup, stage.position, 15.0) == 0.0 \
		and CrowdField.speed_multiplier(lineup, stage.position, 15.0) == 1.0,
		"crowds disperse between Sets")
	check(CrowdField.density(lineup, stage.position + Vector2(500, 0), 25.0) == 0.0,
		"crowds do not exist beyond Audience Zones")

	var needs := Needs.new()
	WalkingCost.apply(needs, 100.0)
	check(absf(needs.get_value(Needs.Kind.ENERGY) - 98.0) < 0.001,
		"Energy cost uses actual distance travelled")
	check(absf(needs.get_value(Needs.Kind.THIRST) - 99.0) < 0.001,
		"Thirst cost uses actual distance travelled")
	var energy := needs.get_value(Needs.Kind.ENERGY)
	WalkingCost.apply(needs, 0.0)
	check(needs.get_value(Needs.Kind.ENERGY) == energy, "attempted movement with zero travel has no Need cost")

	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
