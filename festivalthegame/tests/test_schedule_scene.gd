extends Node
## Scene-level planner journey through its user-facing controls.

var failures := 0
var closed := false

func _ready() -> void:
	var config := RunConfiguration.new()
	config.add_favorite("Metal Favorite", "cc28f5aa-5e19-487c-88e1-e56b022f1fdd")
	config.add_favorite("Pop Favorite", "911c7bbb-172d-4df8-9478-dbff4296e791")
	var lineup := FestivalGenerator.generate(
		config, 77, GenreCatalog.load_bundled(), GenreGraph.load_bundled())
	var planner: ScheduleView = load("res://scenes/schedule.tscn").instantiate()
	add_child(planner)
	planner.closed.connect(func() -> void: closed = true)
	planner.show_schedule(lineup, 1)

	check(planner.visible and planner.displayed_day() == 1, "planner opens on the requested Festival Day")
	check(planner.displayed_set_count() == 36, "one Festival Day lists all 36 Sets")
	var day_one_text := planner.rendered_text()
	check(day_one_text.contains("Metal Favorite") and day_one_text.contains("★"),
		"Favorite Artists are clearly marked")
	check(day_one_text.contains("CONFLICT"), "deliberate Schedule Conflicts are clearly marked")
	check(day_one_text.contains("Main Stage") and day_one_text.contains("metal"),
		"rows show Stage and Genre details")

	var day_two := planner.get_node("Panel/Margin/Content/Days/Day2") as Button
	day_two.pressed.emit()
	check(planner.displayed_day() == 2 and planner.displayed_set_count() == 36,
		"the player can browse another Festival Day")

	var close_button := planner.get_node("Panel/Margin/Content/Close") as Button
	close_button.pressed.emit()
	check(closed and not planner.visible, "the close control dismisses the planner")

	if failures == 0:
		print("ALL SCHEDULE SCENE TESTS PASSED")
	else:
		printerr("%d SCHEDULE SCENE TEST(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
