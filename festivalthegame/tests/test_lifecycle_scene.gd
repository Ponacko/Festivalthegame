extends Node
## Headless flow coverage for the public Festival clock and Run lifecycle.

var failures := 0
var closed_days: Array[int] = []
var started_days: Array[int] = []
var night_days: Array[int] = []
var morning_days: Array[int] = []
var final_requests := 0
var autosave_reasons: Array[String] = []

func _ready() -> void:
	Clock.arena_closed.connect(func(day: int) -> void: closed_days.append(day))
	Clock.day_started.connect(func(day: int) -> void: started_days.append(day))
	Clock.night_started.connect(func(day: int) -> void: night_days.append(day))
	Clock.morning_started.connect(func(day: int) -> void: morning_days.append(day))
	Game.final_scoring_requested.connect(func() -> void: final_requests += 1)
	Game.autosave_requested.connect(func(reason: String) -> void: autosave_reasons.append(reason))

	Game.start_new_run(null, 505)
	Clock.set_paused(false)
	Clock.set_time_scale(1.0)
	Clock.advance(13.0 * 60.0)
	check(FestivalTime.clock_string(Clock.total_minutes) == "00:00", "clock crosses midnight")
	check(FestivalTime.day(Clock.total_minutes) == 1, "midnight does not advance Festival Day")
	Clock.advance(60.0)
	check(closed_days == [1] and night_days == [1], "Day 1 arena close exposes the night hook")
	Clock.advance(10.0 * 60.0)
	check(started_days == [2] and morning_days == [2], "Day 2 morning exposes recap and day hooks")
	Clock.advance(14.0 * 60.0)
	Clock.advance(10.0 * 60.0)
	check(closed_days == [1, 2] and started_days == [2, 3], "all three Festival Days transition in order")
	Clock.advance(14.0 * 60.0)
	check(Clock.total_minutes == FestivalTime.run_end_minute(), "clock stops at the final night boundary")
	check(Clock.paused and Clock.is_complete(), "Run completion stops further simulation")
	check(closed_days == [1, 2, 3], "the final arena closes exactly once")
	check(final_requests == 1 and autosave_reasons.has("run_completed"), "final scoring and autosave hooks fire once")
	var completed_at := Clock.total_minutes
	Clock.advance(100.0)
	check(Clock.total_minutes == completed_at, "a completed Run cannot advance")

	Clock.reset()
	Clock.set_paused(true)
	Clock.advance(10.0)
	check(Clock.total_minutes == 0.0, "pause prevents time advancement")
	Clock.set_paused(false)
	Clock.set_time_scale(4.0)
	Clock.advance(2.5)
	check(Clock.total_minutes == 10.0, "fast-forward consistently scales simulation minutes")

	if failures == 0:
		print("ALL LIFECYCLE TESTS PASSED")
	else:
		printerr("%d LIFECYCLE TEST(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
