extends Node
## Verifies that the playable scene gates a new Run behind setup.

var failures := 0

func _ready() -> void:
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame

	var setup := main.get_node_or_null("SetupLayer/RunSetup") as RunSetupView
	check(setup != null and setup.visible, "a new game opens Run setup")
	check(Clock.paused, "Festival time is paused during setup")
	check(Game.lineup == null, "Festival generation waits for valid setup")

	var config := RunConfiguration.new()
	config.add_favorite("My Favourite", "f66d7266-eb3d-4ef3-b4d8-b7cd992f918b")
	config.set_friend_count(2)
	setup.configuration_submitted.emit(config)
	await get_tree().process_frame

	check(not setup.visible, "submitting setup reveals the Festival")
	check(Game.current_configuration == config, "the Run retains its submitted configuration")
	check(Game.lineup.stages.size() == 4 and Game.lineup.artists.size() >= 100,
		"submitting setup generates the complete Festival")
	check(not Clock.paused, "Festival time starts after setup")

	var pause_button := main.get_node_or_null("Hud/PauseButton") as Button
	var speed_button := main.get_node_or_null("Hud/SpeedButton") as Button
	check(pause_button != null and speed_button != null, "touch HUD exposes pause and fast-forward controls")
	if pause_button != null:
		pause_button.pressed.emit()
		check(Clock.paused, "touch pause control pauses Festival time")
		pause_button.pressed.emit()
		check(not Clock.paused, "touch pause control resumes Festival time")
	if speed_button != null:
		var before_minutes := Clock.total_minutes
		speed_button.pressed.emit()
		check(Clock.time_scale > 1.0, "touch fast-forward control selects a faster speed")
		check(Clock.total_minutes == before_minutes, "selecting fast-forward never advances time automatically")

	var map_button := main.get_node_or_null("Hud/MapButton") as Button
	var festival_map := main.get_node_or_null("MapLayer/FestivalMap") as FestivalMapView
	check(map_button != null and festival_map != null, "playable HUD exposes the in-game map")
	if map_button != null and festival_map != null:
		var player := main.get_node("Player") as Node2D
		var world_position := player.position
		map_button.pressed.emit()
		check(festival_map.visible and Clock.paused, "opening the map pauses the Festival")
		check(player.position == world_position, "opening the map does not move the player")
		var map_close := festival_map.get_node("Panel/Margin/Content/Close") as Button
		map_close.pressed.emit()
		check(not festival_map.visible and player.position == world_position, "closing the map returns in place")

	var schedule_button := main.get_node_or_null("Hud/ScheduleButton") as Button
	var schedule := main.get_node_or_null("PlannerLayer/Schedule") as ScheduleView
	check(schedule_button != null and schedule != null, "playable HUD exposes the schedule planner")
	if schedule_button != null and schedule != null:
		schedule_button.pressed.emit()
		check(schedule.visible and Clock.paused, "opening the planner pauses without moving Festival time")
		var close_button := schedule.get_node("Panel/Margin/Content/Close") as Button
		close_button.pressed.emit()
		check(not schedule.visible and not Clock.paused, "closing the planner resumes the Festival")

	if failures == 0:
		print("ALL MAIN SETUP TESTS PASSED")
	else:
		printerr("%d MAIN SETUP TEST(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
