extends Node
## Public Run flow for water, toilets, Queue time, and interruption.

var failures := 0
var last_message := ""

func _ready() -> void:
	Game.start_new_run(null, 1010)
	Game.facility_queue_finished.connect(func(message: String) -> void: last_message = message)
	Game.facility_queue_interrupted.connect(func(message: String) -> void: last_message = message)
	Clock.set_paused(false)
	var water: FestivalPoint = Game.grounds.points_of_kind(FestivalPoint.Kind.WATER)[0]
	var toilet: FestivalPoint = Game.grounds.points_of_kind(FestivalPoint.Kind.TOILET)[0]

	Game.needs.adjust(Needs.Kind.THIRST, -80.0)
	var thirst_before := Game.needs.get_value(Needs.Kind.THIRST)
	var bladder_before := Game.needs.get_value(Needs.Kind.BLADDER)
	var hunger_before := Game.needs.get_value(Needs.Kind.HUNGER)
	var mood_before := Game.needs.get_value(Needs.Kind.MOOD)
	var budget_before := Game.budget
	var water_wait := Game.queue_preview(water)
	check(Game.start_facility_queue(water, water.position), "player can join the water Queue")
	check(Game.facility_queue.is_active(), "Queue state prevents other actions while waiting")
	Clock.advance(water_wait)
	check(not Game.facility_queue.is_active() and last_message.contains("Water"), "water interaction reports completion")
	check(Game.needs.get_value(Needs.Kind.THIRST) > thirst_before, "free water restores Thirst")
	check(Game.needs.get_value(Needs.Kind.BLADDER) < bladder_before, "drinking water increases Bladder pressure")
	check(Game.budget == budget_before, "water remains free regardless of Budget")
	check(Game.needs.get_value(Needs.Kind.HUNGER) < hunger_before, "passive Needs continue decaying in a Queue")
	check(Game.needs.get_value(Needs.Kind.MOOD) < mood_before, "Queueing drains Mood")
	check(absf(Clock.total_minutes - water_wait) < 0.001, "Queue consumes the previewed Festival time")

	Game.needs.adjust(Needs.Kind.BLADDER, -70.0)
	var uncomfortable := Game.needs.get_value(Needs.Kind.BLADDER)
	var toilet_wait := Game.queue_preview(toilet)
	check(Game.start_facility_queue(toilet, toilet.position),
		"player can join the toilet Queue (preview %.1f min)" % toilet_wait)
	Clock.advance(toilet_wait)
	check(Game.needs.get_value(Needs.Kind.BLADDER) > uncomfortable and last_message.contains("Toilet"),
		"toilet restores Bladder comfort after its Queue and interaction (%.1f -> %.1f; %s)" % [
			uncomfortable, Game.needs.get_value(Needs.Kind.BLADDER), last_message])

	Game.needs.adjust(Needs.Kind.BLADDER, -50.0)
	var before_interruption := Game.needs.get_value(Needs.Kind.BLADDER)
	Game.start_facility_queue(toilet, toilet.position)
	Clock.advance(Game.facility_queue.remaining_minutes * 0.5)
	check(Game.interrupt_facility_queue() and last_message.contains("left"), "player receives clear Queue interruption feedback")
	check(Game.needs.get_value(Needs.Kind.BLADDER) <= before_interruption, "interrupted toilet Queue grants no restoration")

	if failures == 0:
		print("ALL FACILITY TESTS PASSED")
	else:
		printerr("%d FACILITY TEST(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
