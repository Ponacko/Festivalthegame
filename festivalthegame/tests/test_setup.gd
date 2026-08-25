extends SceneTree
## Public-seam tests for offline Run setup.
## Run: godot --headless -s res://tests/test_setup.gd

var failures := 0

func _initialize() -> void:
	test_genre_search_is_normalized_and_stable()
	test_bundled_catalog_contains_the_full_snapshot()
	test_run_configuration_validation()
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)

func test_genre_search_is_normalized_and_stable() -> void:
	print("Genre search:")
	var catalog := GenreCatalog.from_entries([
		{"id": "metal-id", "name": "Heavy Metal"},
		{"id": "ambient-id", "name": "Dark Ambient"},
		{"id": "pop-id", "name": "Pop"},
	])
	var results := catalog.search("  METAL ")
	check(results.size() == 1, "search ignores case and surrounding whitespace")
	check(results[0].id == "metal-id", "search results retain stable MusicBrainz IDs")
	check(catalog.search("", 2).size() == 2, "empty search respects the result limit")

func test_bundled_catalog_contains_the_full_snapshot() -> void:
	print("Bundled Genre catalog:")
	var catalog := GenreCatalog.load_bundled()
	check(catalog.size() >= 2000, "bundled snapshot contains the full MusicBrainz catalog")
	var punk := catalog.search("crust punk", 5)
	check(not punk.is_empty(), "bundled catalog is searchable offline")
	check(not punk[0].id.is_empty(), "bundled genres use stable IDs")

func test_run_configuration_validation() -> void:
	print("Run configuration:")
	var config := RunConfiguration.new()
	check(not config.is_valid(), "at least one Favorite Artist is required")
	config.add_favorite("  My Favourite  ", "genre-id")
	config.set_friend_count(4)
	check(config.is_valid(), "one tagged favorite and four Friends is valid")
	check(config.favorites[0].artist_name == "My Favourite", "artist names are normalized")
	check(config.favorites[0].genre_id == "genre-id", "favorite keeps its Genre ID")
	check(config.friend_count == 4, "Friend count is retained")
	config.set_friend_count(5)
	check(not config.is_valid(), "more than four Friends is rejected")
	config.set_friend_count(0)
	for index in range(10):
		config.add_favorite("Artist %d" % index, "genre-id")
	check(not config.is_valid(), "more than ten Favorite Artists is rejected")
