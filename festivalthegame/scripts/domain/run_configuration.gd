class_name RunConfiguration
extends RefCounted
## Validated choices used to generate one Run.

const MIN_FAVORITES := 1
const MAX_FAVORITES := 10
const MIN_FRIENDS := 0
const MAX_FRIENDS := 4

var favorites: Array[FavoriteArtistPreference] = []
var friend_count := 0

func add_favorite(artist_name: String, genre_id: String) -> void:
	favorites.append(FavoriteArtistPreference.new(artist_name, genre_id))

func set_friend_count(value: int) -> void:
	friend_count = value

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if favorites.size() < MIN_FAVORITES:
		errors.append("Add at least one Favorite Artist.")
	if favorites.size() > MAX_FAVORITES:
		errors.append("Choose no more than %d Favorite Artists." % MAX_FAVORITES)
	if friend_count < MIN_FRIENDS or friend_count > MAX_FRIENDS:
		errors.append("Choose between %d and %d Friends." % [MIN_FRIENDS, MAX_FRIENDS])
	var seen_names := {}
	for favorite in favorites:
		if favorite.artist_name.is_empty():
			errors.append("Every Favorite Artist needs a name.")
		if favorite.genre_id.is_empty():
			errors.append("Every Favorite Artist needs a Genre.")
		var normalized_name := favorite.artist_name.to_lower()
		if seen_names.has(normalized_name):
			errors.append("Favorite Artist names must be unique.")
		seen_names[normalized_name] = true
	return errors

func is_valid() -> bool:
	return validation_errors().is_empty()
