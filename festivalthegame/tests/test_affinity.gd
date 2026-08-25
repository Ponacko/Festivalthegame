extends SceneTree
## Public-seam tests for Genre Distance and Artist affinity.

var failures := 0

func _initialize() -> void:
	test_graph_distance()
	test_bundled_graph()
	test_affinity_uses_nearest_favorite()
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)

func example_graph() -> GenreGraph:
	return GenreGraph.from_edges([
		{"from": "metal", "to": "black-metal", "type": "subgenre"},
		{"from": "black-metal", "to": "atmospheric-black-metal", "type": "subgenre"},
		{"from": "pop", "to": "synthpop", "type": "influence"},
	], PackedStringArray(["metal", "black-metal", "atmospheric-black-metal", "pop", "synthpop", "jazz"]))

func test_graph_distance() -> void:
	print("Genre Distance:")
	var graph := example_graph()
	check(graph.distance("metal", "metal") == 0, "a Genre is distance zero from itself")
	check(graph.distance("metal", "black-metal") == 1, "direct neighbors are distance one")
	check(graph.distance("metal", "atmospheric-black-metal") == 2, "distance follows the shortest path")
	check(graph.distance("metal", "pop") == -1, "disconnected Genres have no distance")
	check(graph.distance("metal", "unknown") == -1, "unknown Genres have no distance")
	check(graph.distance("unknown", "unknown") == -1, "an unknown ID does not match itself")
	check(graph.distance("jazz", "jazz") == 0, "a known isolated Genre matches itself")

func test_bundled_graph() -> void:
	print("Bundled Genre graph:")
	var graph := GenreGraph.load_bundled()
	check(graph.genre_count() >= 2000, "snapshot contains the complete Genre node set")
	check(graph.edge_count() >= 3000, "snapshot contains MusicBrainz Genre relationships")
	check(graph.distance("cc28f5aa-5e19-487c-88e1-e56b022f1fdd", "12568698-97cc-49a9-80ab-9c5e3fe4dd33") == 1,
		"bundled graph links metal directly to black metal")
	check(graph.distance("12568698-97cc-49a9-80ab-9c5e3fe4dd33", "d14a4c4a-bea5-4b08-b945-59b048acd2d5") == 1,
		"bundled graph links black metal to atmospheric black metal")

func test_affinity_uses_nearest_favorite() -> void:
	print("Artist affinity:")
	var calculator := ArtistAffinity.new(example_graph())
	var favorites: Array[FavoriteArtistPreference] = [
		FavoriteArtistPreference.new("The Favorite", "metal"),
		FavoriteArtistPreference.new("Pop Favorite", "pop"),
	]
	var favorite := Artist.new("The Favorite", "metal", 0.9, true)
	var nearby := Artist.new("Nearby", "black-metal", 0.5, false)
	var distant := Artist.new("Distant", "atmospheric-black-metal", 0.5, false)
	var nearest_second := Artist.new("Nearest second", "synthpop", 0.5, false)
	var disconnected := Artist.new("Disconnected", "jazz", 0.5, false)
	check(calculator.for_artist(favorite, favorites) == 1.0, "a Favorite Artist has affinity 1.0")
	check(absf(calculator.for_artist(nearby, favorites) - 0.612) < 0.001,
		"a direct Genre neighbor receives the worked-example affinity")
	check(calculator.for_artist(distant, favorites) < calculator.for_artist(nearby, favorites),
		"affinity decays with increasing Genre Distance")
	check(absf(calculator.for_artist(nearest_second, favorites) - 0.612) < 0.001,
		"multiple favorites use the shortest available distance")
	check(calculator.for_artist(disconnected, favorites) == 0.10,
		"disconnected Genres receive the affinity floor")
