class_name GenreCatalog
extends RefCounted
## Offline searchable view of the bundled MusicBrainz Genre taxonomy.

const BUNDLED_PATH := "res://data/musicbrainz_genres.json"

var _entries: Array[GenreEntry] = []
var _by_id := {}

static func from_entries(rows: Array) -> GenreCatalog:
	var catalog := GenreCatalog.new()
	for row in rows:
		var entry := GenreEntry.new(str(row.get("id", "")), str(row.get("name", "")).strip_edges())
		if entry.id.is_empty() or entry.display_name.is_empty() or catalog._by_id.has(entry.id):
			continue
		catalog._entries.append(entry)
		catalog._by_id[entry.id] = entry
	catalog._entries.sort_custom(func(a: GenreEntry, b: GenreEntry) -> bool:
		return a.display_name.naturalnocasecmp_to(b.display_name) < 0)
	return catalog

static func load_bundled() -> GenreCatalog:
	if not FileAccess.file_exists(BUNDLED_PATH):
		push_error("Bundled MusicBrainz Genre snapshot is missing")
		return GenreCatalog.new()
	var file := FileAccess.open(BUNDLED_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		push_error("Bundled MusicBrainz Genre snapshot is invalid")
		return GenreCatalog.new()
	return from_entries(parsed)

func size() -> int:
	return _entries.size()

func all_entries() -> Array[GenreEntry]:
	return _entries.duplicate()

func find_by_id(genre_id: String) -> GenreEntry:
	return _by_id.get(genre_id)

func search(query: String, limit := 12) -> Array[GenreEntry]:
	var matches: Array[GenreEntry] = []
	if limit <= 0:
		return matches
	var needle := query.strip_edges().to_lower()
	for entry in _entries:
		if needle.is_empty() or entry.display_name.to_lower().contains(needle):
			matches.append(entry)
			if matches.size() >= limit:
				break
	return matches
