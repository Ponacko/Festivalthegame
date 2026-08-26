class_name GenreSoundMap
extends RefCounted
## Deterministic mapping from bundled taxonomy names to four loop neighborhoods.

const LOOP_PATHS := {
	"rock": "res://audio/loops/rock.wav",
	"electronic": "res://audio/loops/electronic.wav",
	"hiphop": "res://audio/loops/hiphop.wav",
	"acoustic": "res://audio/loops/acoustic.wav",
}

static func category_for(genre_id: String, catalog: GenreCatalog) -> String:
	var entry := catalog.find_by_id(genre_id)
	var name := entry.display_name.to_lower() if entry != null else ""
	if _contains_any(name, ["rock", "metal", "punk", "grunge", "hardcore"]):
		return "rock"
	if _contains_any(name, ["electronic", "techno", "house", "dance", "trance", "ambient"]):
		return "electronic"
	if _contains_any(name, ["hip hop", "rap", "trap", "r&b", "funk"]):
		return "hiphop"
	if _contains_any(name, ["folk", "jazz", "classical", "country", "acoustic", "blues"]):
		return "acoustic"
	var categories := ["rock", "electronic", "hiphop", "acoustic"]
	return categories[abs(genre_id.hash()) % categories.size()]

static func path_for(genre_id: String, catalog: GenreCatalog) -> String:
	return LOOP_PATHS[category_for(genre_id, catalog)]

static func all_assets_available() -> bool:
	for path in LOOP_PATHS.values():
		if not ResourceLoader.exists(path):
			return false
	return ResourceLoader.exists("res://audio/loops/crowd.wav")

static func _contains_any(value: String, terms: Array) -> bool:
	for term in terms:
		if value.contains(term):
			return true
	return false
