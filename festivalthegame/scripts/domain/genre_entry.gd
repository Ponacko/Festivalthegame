class_name GenreEntry
extends RefCounted
## One searchable Genre from the bundled MusicBrainz snapshot.

var id: String
var display_name: String

func _init(p_id := "", p_display_name := "") -> void:
	id = p_id
	display_name = p_display_name

