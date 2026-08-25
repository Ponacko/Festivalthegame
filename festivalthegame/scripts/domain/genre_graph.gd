class_name GenreGraph
extends RefCounted
## Offline undirected graph of typed MusicBrainz Genre relationships.

const BUNDLED_PATH := "res://data/musicbrainz_genre_graph.json"

var _neighbors := {}
var _known := {}
var _edge_total := 0

static func from_edges(edges: Array, genre_ids := PackedStringArray()) -> GenreGraph:
	var graph := GenreGraph.new()
	for genre_id in genre_ids:
		graph._register(str(genre_id))
	for edge in edges:
		var from_id := str(edge.get("from", ""))
		var to_id := str(edge.get("to", ""))
		if from_id.is_empty() or to_id.is_empty() or from_id == to_id:
			continue
		graph._connect(from_id, to_id)
	return graph

static func load_bundled() -> GenreGraph:
	if not FileAccess.file_exists(BUNDLED_PATH):
		push_error("Bundled MusicBrainz Genre graph is missing")
		return GenreGraph.new()
	var file := FileAccess.open(BUNDLED_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not parsed.get("edges", null) is Array:
		push_error("Bundled MusicBrainz Genre graph is invalid")
		return GenreGraph.new()
	return from_edges(parsed.edges, PackedStringArray(parsed.get("genre_ids", [])))

func distance(from_id: String, to_id: String) -> int:
	if not _known.has(from_id) or not _known.has(to_id):
		return -1
	if from_id == to_id:
		return 0
	if not _neighbors.has(from_id) or not _neighbors.has(to_id):
		return -1
	var visited := {from_id: true}
	var frontier: Array[String] = [from_id]
	var current_distance := 0
	while not frontier.is_empty():
		current_distance += 1
		var next_frontier: Array[String] = []
		for genre_id in frontier:
			for neighbor_id: String in _neighbors[genre_id]:
				if neighbor_id == to_id:
					return current_distance
				if not visited.has(neighbor_id):
					visited[neighbor_id] = true
					next_frontier.append(neighbor_id)
		frontier = next_frontier
	return -1

func genre_count() -> int:
	return _known.size()

func edge_count() -> int:
	return _edge_total

func distances_from(start_ids: PackedStringArray) -> Dictionary:
	var distances := {}
	var frontier: Array[String] = []
	for genre_id in start_ids:
		if _known.has(genre_id) and not distances.has(genre_id):
			distances[genre_id] = 0
			frontier.append(genre_id)
	while not frontier.is_empty():
		var next_frontier: Array[String] = []
		for genre_id in frontier:
			var next_distance: int = distances[genre_id] + 1
			for neighbor_id: String in _neighbors[genre_id]:
				if not distances.has(neighbor_id):
					distances[neighbor_id] = next_distance
					next_frontier.append(neighbor_id)
		frontier = next_frontier
	return distances

func _connect(from_id: String, to_id: String) -> void:
	_register(from_id)
	_register(to_id)
	if to_id not in _neighbors[from_id]:
		_neighbors[from_id].append(to_id)
		_neighbors[to_id].append(from_id)
		_edge_total += 1

func _register(genre_id: String) -> void:
	if genre_id.is_empty() or _known.has(genre_id):
		return
	_known[genre_id] = true
	if not _neighbors.has(genre_id):
		_neighbors[genre_id] = [] as Array[String]
