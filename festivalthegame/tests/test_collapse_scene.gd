extends Node
## Public Run flow for Collapse, First Aid recovery, and event recording.

var failures := 0
var relocations: Array[Vector2] = []
var starts := 0

func _ready() -> void:
	Game.collapse_started.connect(func(_kind: int) -> void: starts += 1)
	Game.player_relocation_requested.connect(func(position: Vector2) -> void: relocations.append(position))
	for kind in [Needs.Kind.HUNGER, Needs.Kind.THIRST, Needs.Kind.ENERGY]:
		Game.start_new_run(null, 1212 + kind)
		Game.award_bonus("score before collapse", 5.0)
		var score_before := Game.current_score()
		var budget_before := Game.budget
		var time_before := Clock.total_minutes
		Game.needs.adjust(kind, -Needs.MAX)
		check(Game.check_for_collapse(), "%s reaching zero triggers Collapse" % Needs.NAMES[kind])
		check(absf(Clock.total_minutes - time_before - Game.COLLAPSE_MINUTES) < 0.001,
			"Collapse advances the configured Festival time")
		check(Game.needs.get_value(kind) == Game.COLLAPSE_RESTORE,
			"offending %s is partly restored" % Needs.NAMES[kind])
		check(Game.needs.get_value(Needs.Kind.MOOD) == Game.COLLAPSE_MOOD,
			"player wakes with Mood floored")
		check(Game.current_score() == score_before and Game.budget == budget_before,
			"Collapse preserves earned score and Budget")
		var first_aid := Game.grounds.points_of_kind(FestivalPoint.Kind.FIRST_AID)[0]
		check(relocations[-1] == first_aid.position, "player wakes at the First Aid Tent")
		check(Game.run_events[-1].event_type == "collapse", "Collapse is recorded for recaps and war stories")

	Game.start_new_run(null, 1220)
	var before_starts := starts
	Game.needs.adjust(Needs.Kind.HUNGER, -Needs.MAX)
	Game.needs.adjust(Needs.Kind.THIRST, -Needs.MAX)
	Game.needs.adjust(Needs.Kind.ENERGY, -Needs.MAX)
	check(Game.check_for_collapse(), "simultaneous survival failures trigger a Collapse")
	check(starts == before_starts + 1 and Game.run_events.size() == 1,
		"simultaneous empty Needs produce one deterministic blackout")
	check(Game.run_events[0].detail.contains("Hunger, Thirst, Energy"),
		"the event deterministically records every simultaneous failure")
	check(Game.needs.get_value(Needs.Kind.HUNGER) == Game.COLLAPSE_RESTORE \
		and Game.needs.get_value(Needs.Kind.THIRST) == Game.COLLAPSE_RESTORE \
		and Game.needs.get_value(Needs.Kind.ENERGY) == Game.COLLAPSE_RESTORE,
		"all simultaneous offending Needs are restored together")
	check(not Game.check_for_collapse(), "restored Needs do not duplicate the Collapse next frame")

	if failures == 0:
		print("ALL COLLAPSE TESTS PASSED")
	else:
		printerr("%d COLLAPSE TEST(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
