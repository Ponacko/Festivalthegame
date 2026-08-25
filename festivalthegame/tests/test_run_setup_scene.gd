extends Node
## Scene-level setup journey through user-facing controls and the public signal.

var failures := 0
var submitted_configuration: RunConfiguration

func _ready() -> void:
	var setup: RunSetupView = load("res://scenes/run_setup.tscn").instantiate()
	add_child(setup)
	setup.configuration_submitted.connect(func(config: RunConfiguration) -> void:
		submitted_configuration = config)

	var start_button := setup.get_node("Panel/Margin/Content/StartButton") as Button
	start_button.pressed.emit()
	check(submitted_configuration == null, "invalid setup does not start a Run")
	check(setup.get_node("Panel/Margin/Content/Error").text.contains("Favorite"),
		"invalid setup explains what is missing")

	var artist_edit := setup.get_node("Panel/Margin/Content/Entry/ArtistName") as LineEdit
	var genre_edit := setup.get_node("Panel/Margin/Content/Entry/GenreSearch") as LineEdit
	var suggestions := setup.get_node("Panel/Margin/Content/GenreSuggestions") as ItemList
	artist_edit.text = "My Favourite"
	genre_edit.text = "crust punk"
	genre_edit.text_changed.emit(genre_edit.text)
	check(suggestions.item_count > 0, "typing a Genre shows offline suggestions")
	suggestions.select(0)
	suggestions.item_activated.emit(0)

	var add_button := setup.get_node("Panel/Margin/Content/Entry/AddFavorite") as Button
	add_button.pressed.emit()
	check(setup.favorite_count() == 1, "selected Artist and Genre are added")

	var friends := setup.get_node("Panel/Margin/Content/FriendCount") as SpinBox
	friends.value = 4
	start_button.pressed.emit()
	check(submitted_configuration != null, "valid setup emits a Run configuration")
	check(submitted_configuration.favorites[0].artist_name == "My Favourite",
		"submitted configuration keeps the Favorite Artist")
	check(submitted_configuration.friend_count == 4,
		"submitted configuration keeps the Friend count")

	if failures == 0:
		print("ALL RUN SETUP SCENE TESTS PASSED")
	else:
		printerr("%d RUN SETUP SCENE TEST(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
