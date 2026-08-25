extends Node
## Public flow for Bladder accident, persistent penalty, toilet, and camp recovery.

var failures := 0

func _ready() -> void:
	Game.start_new_run(null, 1313)
	Game.award_bonus("score before accident", 7.0)
	var score_before := Game.current_score()
	Game.needs.adjust(Needs.Kind.BLADDER, -Needs.MAX)
	check(Game.check_for_accident(), "Bladder reaching zero triggers one accident")
	check(not Game.is_collapsed(), "empty Bladder does not trigger Collapse")
	check(Game.has_accident_penalty() and Game.needs.get_value(Needs.Kind.MOOD) == Game.ACCIDENT_MOOD,
		"accident crashes Mood and applies a visible status")
	check(Game.needs.social_penalty == Game.ACCIDENT_SOCIAL_PENALTY,
		"accident applies the configured Social penalty")
	check(Game.run_events.size() == 1 and Game.run_events[0].event_type == "bladder_accident",
		"accident is recorded for recaps and war stories")
	check(not Game.check_for_accident() and Game.run_events.size() == 1,
		"continued Bladder drain cannot stack accidents while dirty")

	var toilet := Game.grounds.points_of_kind(FestivalPoint.Kind.TOILET)[0]
	Game.start_facility_queue(toilet, toilet.position)
	Clock.advance(Game.facility_queue.remaining_minutes)
	check(Game.needs.get_value(Needs.Kind.BLADDER) == Needs.MAX, "toilet restores Bladder after an accident")
	check(Game.has_accident_penalty() and Game.needs.social_penalty == Game.ACCIDENT_SOCIAL_PENALTY,
		"ordinary toilet use does not clear the accident penalty")

	var time_before := Clock.total_minutes
	check(not Game.change_at_camp(Vector2.ZERO), "changing is rejected away from the selected campsite")
	check(Game.change_at_camp(Game.grounds.camp.interaction_position), "player can change at the selected campsite")
	check(absf(Clock.total_minutes - time_before - Game.CHANGE_CLOTHES_MINUTES) < 0.001,
		"changing clothes consumes configured Festival time")
	check(not Game.has_accident_penalty() and Game.needs.social_penalty == 0.0,
		"changing at camp clears the persistent Social penalty")
	check(Game.current_score() == score_before, "accident and changing never subtract earned score")

	if failures == 0:
		print("ALL ACCIDENT TESTS PASSED")
	else:
		printerr("%d ACCIDENT TEST(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
