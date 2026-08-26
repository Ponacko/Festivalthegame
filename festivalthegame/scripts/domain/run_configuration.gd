class_name RunConfiguration
extends RefCounted
## Validated choices used to generate one Run.

const MIN_FAVORITES := 1
const MAX_FAVORITES := 10
const MIN_FRIENDS := 0
const MAX_FRIENDS := 4

var favorites: Array[FavoriteArtistPreference] = []
var friend_count := 0
var campsite_id := ""
var _locked := false

func add_favorite(artist_name: String, genre_id: String) -> void:
	if _locked:
		return
	favorites.append(FavoriteArtistPreference.new(artist_name, genre_id))

func set_friend_count(value: int) -> void:
	if _locked:
		return
	friend_count = value

func select_campsite(value: String) -> bool:
	if _locked or CampsiteCatalog.find(value) == null:
		return false
	campsite_id = value
	return true

func lock() -> void:
	_locked = true

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if favorites.size() < MIN_FAVORITES:
		errors.append("Add at least one Favorite Artist.")
	if favorites.size() > MAX_FAVORITES:
		errors.append("Choose no more than %d Favorite Artists." % MAX_FAVORITES)
	if friend_count < MIN_FRIENDS or friend_count > MAX_FRIENDS:
		errors.append("Choose between %d and %d Friends." % [MIN_FRIENDS, MAX_FRIENDS])
	if CampsiteCatalog.find(campsite_id) == null:
		errors.append("Choose one campsite for the Run.")
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

func to_dictionary() -> Dictionary:
	var saved_favorites: Array[Dictionary] = []
	for favorite in favorites:
		saved_favorites.append({"artist_name": favorite.artist_name, "genre_id": favorite.genre_id})
	return {"favorites": saved_favorites, "friend_count": friend_count, "campsite_id": campsite_id}

static func from_dictionary(value: Dictionary) -> RunConfiguration:
	var configuration := RunConfiguration.new()
	for favorite in value.get("favorites", []):
		configuration.add_favorite(str(favorite.get("artist_name", "")), str(favorite.get("genre_id", "")))
	configuration.set_friend_count(int(value.get("friend_count", 0)))
	configuration.select_campsite(str(value.get("campsite_id", "")))
	return configuration
