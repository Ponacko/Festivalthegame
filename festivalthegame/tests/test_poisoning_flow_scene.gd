extends Node
## Purchase-to-onset integration with standard accident/Collapse systems.

var failures := 0

func _ready() -> void:
	Game.start_new_run(null, 1415)
	Clock.set_paused(false)
	var vendor: Vendor = Game.grounds.vendors[0]
	var risky_food: VendorItem = vendor.archetype.menu[0]
	risky_food.poisoning_risk = 1.0
	var score_before := Game.current_score()
	var rolls_before := Game.poisoning_roll_count
	Game.start_vendor_purchase(vendor, risky_food, vendor.point.position)
	Clock.advance(Game.facility_queue.remaining_minutes)
	check(Game.poisoning_roll_count == rolls_before + 1, "eating rolls configured poisoning risk exactly once")
	check(Game.food_poisoning.is_pending(), "successful roll schedules symptoms instead of applying them immediately")
	var thirst_after_food := Game.needs.get_value(Needs.Kind.THIRST)
	Clock.advance_game_minutes(FoodPoisoning.ONSET_DELAY_MINUTES - 1.0)
	check(Game.needs.get_value(Needs.Kind.THIRST) < thirst_after_food,
		"only normal passive decay applies before onset")
	Clock.advance_game_minutes(1.0)
	check(Game.food_poisoning.is_active(), "poisoning becomes active after its delay")
	check(not Game.is_action_locked(), "Food Poisoning never takes movement control away")
	var events_before := Game.run_events.size()
	Clock.advance_game_minutes(125.0)
	check(Game.check_for_accident(), "poisoning pressure contributes to the standard Bladder accident")
	check(Game.run_events.size() > events_before, "onset and urgency are recorded as Run events")
	check(Game.current_score() == score_before, "poisoning never directly subtracts Enjoyment Score")
	var toilet := Game.grounds.points_of_kind(FestivalPoint.Kind.TOILET)[0]
	Game.start_facility_queue(toilet, toilet.position)
	Clock.advance(Game.facility_queue.remaining_minutes)
	var restored := Game.needs.get_value(Needs.Kind.BLADDER)
	Clock.advance_game_minutes(10.0)
	check(Game.needs.get_value(Needs.Kind.BLADDER) < restored,
		"toilet helps immediately but active symptoms resume Bladder pressure")

	if failures == 0:
		print("ALL POISONING FLOW TESTS PASSED")
	else:
		printerr("%d POISONING FLOW TEST(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
