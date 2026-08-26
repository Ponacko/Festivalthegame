extends Node
## Game-level Mosh participation ledger, event, and First Aid treatment.

var failures := 0

func _ready() -> void:
	var config := RunConfiguration.new()
	config.add_favorite("Metal Favorite", "cc28f5aa-5e19-487c-88e1-e56b022f1fdd")
	config.select_campsite("camp_1")
	Game.start_new_run(config, 1617)
	var mosh_set: FestivalSet
	for festival_set in Game.lineup.sets:
		if Game.mosh_genres.has(festival_set.artist.genre_id):
			mosh_set = festival_set
			break
	check(mosh_set != null, "generated taste-biased Festival contains a mosh-eligible Set")
	Clock.advance_game_minutes(mosh_set.start_minute + (mosh_set.end_minute - mosh_set.start_minute) * 0.5)
	var player_position := mosh_set.stage.position
	var player: CharacterBody2D = load("res://scenes/player.tscn").instantiate()
	player.position = player_position
	add_child(player)
	var hud: CanvasLayer = load("res://scripts/ui/hud.gd").new()
	add_child(hud)
	await get_tree().process_frame
	await get_tree().process_frame
	var mosh_button := hud.get_node("MoshButton") as Button
	check(mosh_button.visible and mosh_button.text.contains("Join Mosh Pit"),
		"touch HUD clearly offers opt-in Mosh participation")
	mosh_button.pressed.emit()
	check(Game.mosh.is_active() and mosh_button.text.contains("Join"),
		"touch control explicitly enters the Mosh Pit")
	mosh_button.pressed.emit()
	check(not Game.mosh.is_active(), "the same touch control explicitly leaves the Mosh Pit")
	check(Game.join_mosh(mosh_set, player_position), "player explicitly enters the active Front Mosh Pit")
	Game.mosh.risk_per_minute = 1.0
	var score_before := Game.current_score()
	Game.advance_mosh(1.0, player_position)
	check(Game.current_score() > score_before and Game.score_ledger.entries[-1].source_name.contains("Mosh Pit"),
		"Mosh enjoyment is a named scoring-ledger bonus")
	check(Game.mosh.injured and Game.run_events.any(func(event: RunEvent) -> bool: return event.event_type == "injury"),
		"deterministic Injury is visible in Run event history")
	var injured_score := Game.current_score()
	var budget_before := Game.budget
	check(not Game.treat_injury(Vector2.ZERO), "Injury treatment is rejected away from First Aid")
	var first_aid := Game.grounds.points_of_kind(FestivalPoint.Kind.FIRST_AID)[0]
	var time_before := Clock.total_minutes
	check(Game.treat_injury(first_aid.position), "First Aid treats Injury")
	check(Clock.total_minutes >= time_before + Game.INJURY_TREATMENT_MINUTES,
		"Injury treatment consumes Festival time")
	check(not Game.mosh.injured and Game.needs.mood_penalty == 0.0,
		"treatment clears speed and Mood penalties")
	check(Game.current_score() == injured_score and Game.budget == budget_before,
		"First Aid never spends Budget or subtracts score")

	if failures == 0:
		print("ALL MOSH FLOW TESTS PASSED")
	else:
		printerr("%d MOSH FLOW TEST(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
