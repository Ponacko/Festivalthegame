extends SceneTree
## Pure eligibility, timing, reward, risk, and Injury tests.

var failures := 0

func _initialize() -> void:
	var metal_id := "cc28f5aa-5e19-487c-88e1-e56b022f1fdd"
	var neighbor_id := "mosh-neighbor"
	var graph := GenreGraph.from_edges([{"from": metal_id, "to": neighbor_id}], [metal_id, neighbor_id, "ambient"])
	var eligible := MoshPit.build_eligible_genres(graph)
	var stage := Stage.new("stage", "Stage", Vector2.ZERO)
	var mosh_artist := Artist.new("Mosh", neighbor_id, 0.8, false, 0.7)
	var quiet_artist := Artist.new("Quiet", "ambient", 0.8, false, 0.7)
	var mosh_set := FestivalSet.new(mosh_artist, stage, 0.0, 100.0)
	var quiet_set := FestivalSet.new(quiet_artist, stage, 0.0, 100.0)
	check(MoshPit.is_available(mosh_set, stage.position, 25.0, eligible),
		"eligible Genre exposes a Mosh Pit at peak start")
	check(not MoshPit.is_available(mosh_set, stage.position, 24.9, eligible) \
		and not MoshPit.is_available(mosh_set, stage.position, 75.1, eligible),
		"Mosh Pit exists only during the middle peak portion")
	check(not MoshPit.is_available(mosh_set, stage.position + Vector2(Audience.FRONT_RADIUS + 1, 0), 50.0, eligible),
		"Mosh Pit exists only in Front")
	check(not MoshPit.is_available(quiet_set, stage.position, 50.0, eligible),
		"non-mosh Genre never exposes a Mosh Pit")

	var rng := RandomNumberGenerator.new()
	rng.seed = 1616
	var state := MoshState.new()
	var needs := Needs.new()
	state.join(mosh_set)
	var energy_before := needs.get_value(Needs.Kind.ENERGY)
	var mood_before := needs.get_value(Needs.Kind.MOOD)
	var result := state.advance(2.0, needs, rng, 0.0)
	check(result.bonus_points > 0.0 and needs.get_value(Needs.Kind.MOOD) >= mood_before,
		"Mosh time grants bonus points and strong Mood gain")
	check(needs.get_value(Needs.Kind.ENERGY) < energy_before, "Mosh time heavily drains Energy")
	state.leave()
	check(not state.is_active(), "leaving the Mosh Pit is under player control")

	state.join(mosh_set)
	var injury := state.advance(1.0, needs, rng, 1.0)
	check(injury.injured_now and state.injured, "Injury risk is rolled for attended game-minutes")
	check(state.speed_multiplier() == 0.5 and needs.mood_penalty == MoshState.INJURY_MOOD_PENALTY,
		"Injury halves speed and applies a persistent Mood debuff")
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
