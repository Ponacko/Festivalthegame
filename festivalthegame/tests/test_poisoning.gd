extends SceneTree
## Pure deterministic risk and timed symptom tests.

var failures := 0

func _initialize() -> void:
	var first_rng := RandomNumberGenerator.new()
	var second_rng := RandomNumberGenerator.new()
	first_rng.seed = 1414
	second_rng.seed = 1414
	var first_rolls := []
	var second_rolls := []
	for index in range(12):
		first_rolls.append(FoodPoisoning.roll(0.35, first_rng))
		second_rolls.append(FoodPoisoning.roll(0.35, second_rng))
	check(first_rolls == second_rolls, "poisoning rolls are deterministic from the Run RNG")
	check(not FoodPoisoning.roll(0.0, first_rng), "zero risk can never poison")
	check(FoodPoisoning.roll(1.0, first_rng), "maximum risk always poisons")

	var illness := FoodPoisoning.new()
	var needs := Needs.new()
	check(illness.schedule(), "successful roll schedules delayed poisoning")
	var before := needs.get_value(Needs.Kind.THIRST)
	check(illness.advance(FoodPoisoning.ONSET_DELAY_MINUTES - 1.0, needs).is_empty(),
		"symptoms do not apply before delayed onset")
	check(needs.get_value(Needs.Kind.THIRST) == before, "pending poisoning has no symptom drain")
	var onset := illness.advance(1.0, needs)
	check(onset.has("onset") and illness.is_active(), "illness becomes visible at delayed onset")
	needs.adjust(Needs.Kind.MOOD, -10.0)
	var symptoms := illness.advance(65.0, needs)
	check(needs.get_value(Needs.Kind.THIRST) < before and needs.get_value(Needs.Kind.BLADDER) < Needs.MAX,
		"active illness rapidly drains Thirst and Bladder")
	check(needs.get_value(Needs.Kind.MOOD) <= FoodPoisoning.MOOD_CEILING,
		"active illness holds Mood at its configured floor")
	check(symptoms.count("urgent") >= 2, "active illness creates repeated urgent toilet episodes")
	var recovery := illness.advance(FoodPoisoning.ACTIVE_MINUTES, needs)
	check(recovery.has("recovered") and not illness.is_active(), "illness expires after its configured duration")
	var thirst_after_recovery := needs.get_value(Needs.Kind.THIRST)
	illness.advance(30.0, needs)
	check(needs.get_value(Needs.Kind.THIRST) == thirst_after_recovery,
		"symptom drain stops after recovery")
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
