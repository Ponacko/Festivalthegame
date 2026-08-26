extends Node
## Durable daily recap projection and exactly-once lifecycle behavior.

var failures := 0
var recap_requests := 0

func _ready() -> void:
	var ledger := ScoreLedger.new()
	var needs := Needs.new()
	var empty := DayRecap.build(1, ledger, [], 0.0, needs)
	check(empty.attended_sets.is_empty() and empty.text().contains("No Sets attended"),
		"empty days produce a readable recap")
	var stage := Stage.new("s", "North Stage", Vector2.ZERO)
	var set := FestivalSet.new(Artist.new("Recap Artist", "genre", 1.0), stage, 20.0, 80.0)
	var entry := ledger.record_attendance(set, 25.0, 1.0, 1.3, 1.0)
	entry.recorded_at = 40.0
	entry.audience_zone = "Front"
	ledger.record_bonus("Shared experience — Recap Artist", 4.0).recorded_at = 45.0
	var events: Array[RunEvent] = [
		RunEvent.new("collapse", 50.0, "Energy"),
		RunEvent.new("night_summary", FestivalTime.festival_day_start(2), "Slept 300 min"),
		RunEvent.new("injury", FestivalTime.festival_day_start(2) + 10.0, "Day 2 event"),
	]
	var recap := DayRecap.build(1, ledger, events, 18.0, needs)
	var text := recap.text()
	check(text.contains("Recap Artist") and text.contains("25") and text.contains("Front") and text.contains("32.5"),
		"recap lists Set minutes, Audience Zone, score, and relevant bonus")
	check(text.contains("€18") and text.contains("Energy") and text.contains("Slept 300"),
		"recap includes Budget, Needs, disasters, and night choice")
	check(not text.contains("Day 2 event"), "events are attributed only to the completed day")

	var config := RunConfiguration.new()
	config.add_favorite("Favorite", "cc28f5aa-5e19-487c-88e1-e56b022f1fdd")
	config.select_campsite("camp_1")
	Game.start_new_run(config, 2020)
	Game.morning_recap_requested.connect(func(_day: int) -> void: recap_requests += 1)
	Clock.advance_game_minutes(FestivalTime.festival_day_start(2))
	check(recap_requests == 1 and Game.pending_recap != null,
		"Day 1 recap is requested exactly once")
	Clock.advance_game_minutes(1.0)
	check(recap_requests == 1, "advancing cannot duplicate a recap")
	Game.dismiss_recap()
	check(Game.pending_recap == null, "player explicitly dismisses the pending recap")
	Game.start_new_run(config, 2021)
	Clock.advance_game_minutes(FestivalTime.run_end_minute())
	check(Game.pending_recap == null, "Day 3 proceeds directly to final scoring")
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
