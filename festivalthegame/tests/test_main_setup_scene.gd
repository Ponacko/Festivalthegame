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
	check(not Clock.paused, "Festival time starts after setup")

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
