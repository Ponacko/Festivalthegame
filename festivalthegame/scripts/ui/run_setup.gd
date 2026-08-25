class_name RunSetupView
extends Control
## Touch-first entry point for one Run's taste and group configuration.

signal configuration_submitted(configuration: RunConfiguration)

@onready var _artist_name: LineEdit = $Panel/Margin/Content/Entry/ArtistName
@onready var _genre_search: LineEdit = $Panel/Margin/Content/Entry/GenreSearch
@onready var _suggestions: ItemList = $Panel/Margin/Content/GenreSuggestions
@onready var _favorites_label: Label = $Panel/Margin/Content/Favorites
@onready var _friend_count: SpinBox = $Panel/Margin/Content/FriendCount
@onready var _campsite: OptionButton = $Panel/Margin/Content/Campsite
@onready var _campsite_details: Label = $Panel/Margin/Content/CampsiteDetails
@onready var _error: Label = $Panel/Margin/Content/Error

var _catalog: GenreCatalog
var _favorites: Array[FavoriteArtistPreference] = []
var _visible_genres: Array[GenreEntry] = []
var _selected_genre: GenreEntry
var _selected_campsite_id := ""

func _ready() -> void:
	_catalog = GenreCatalog.load_bundled()
	_genre_search.text_changed.connect(_on_genre_search_changed)
	_suggestions.item_selected.connect(_on_genre_selected)
	_suggestions.item_activated.connect(_on_genre_selected)
	$Panel/Margin/Content/Entry/AddFavorite.pressed.connect(_on_add_favorite)
	$Panel/Margin/Content/RemoveFavorite.pressed.connect(_on_remove_favorite)
	$Panel/Margin/Content/StartButton.pressed.connect(_on_start)
	for profile in CampsiteCatalog.all_profiles():
		_campsite.add_item(profile.display_name)
		_campsite.set_item_metadata(_campsite.item_count - 1, profile.id)
	_campsite.select(-1)
	_campsite.item_selected.connect(_on_campsite_selected)
	_on_genre_search_changed("")
	_update_favorites_label()

func favorite_count() -> int:
	return _favorites.size()

func reset() -> void:
	_favorites.clear()
	_artist_name.clear()
	_genre_search.clear()
	_friend_count.value = 0
	_campsite.select(-1)
	_selected_campsite_id = ""
	_campsite_details.text = "Select a campsite to compare its trade-offs."
	_selected_genre = null
	_error.text = ""
	_on_genre_search_changed("")
	_update_favorites_label()

func _on_genre_search_changed(query: String) -> void:
	_selected_genre = null
	_visible_genres = _catalog.search(query, 12)
	_suggestions.clear()
	for genre in _visible_genres:
		_suggestions.add_item(genre.display_name)
		_suggestions.set_item_tooltip(_suggestions.item_count - 1, genre.id)

func _on_genre_selected(index: int) -> void:
	if index < 0 or index >= _visible_genres.size():
		return
	_selected_genre = _visible_genres[index]
	_genre_search.set_block_signals(true)
	_genre_search.text = _selected_genre.display_name
	_genre_search.caret_column = _genre_search.text.length()
	_genre_search.set_block_signals(false)
	_error.text = ""

func _on_add_favorite() -> void:
	var name := _artist_name.text.strip_edges()
	if name.is_empty():
		_error.text = "Enter a Favorite Artist name."
		return
	if _selected_genre == null:
		_error.text = "Select a Genre from the suggestions."
		return
	if _favorites.size() >= RunConfiguration.MAX_FAVORITES:
		_error.text = "Choose no more than %d Favorite Artists." % RunConfiguration.MAX_FAVORITES
		return
	for favorite in _favorites:
		if favorite.artist_name.to_lower() == name.to_lower():
			_error.text = "That Favorite Artist is already listed."
			return
	_favorites.append(FavoriteArtistPreference.new(name, _selected_genre.id))
	_artist_name.clear()
	_genre_search.clear()
	_selected_genre = null
	_error.text = ""
	_on_genre_search_changed("")
	_update_favorites_label()

func _on_remove_favorite() -> void:
	if _favorites.is_empty():
		return
	_favorites.pop_back()
	_error.text = ""
	_update_favorites_label()

func _on_start() -> void:
	var configuration := RunConfiguration.new()
	for favorite in _favorites:
		configuration.add_favorite(favorite.artist_name, favorite.genre_id)
	configuration.set_friend_count(int(_friend_count.value))
	configuration.select_campsite(_selected_campsite_id)
	var errors := configuration.validation_errors()
	if not errors.is_empty():
		_error.text = "\n".join(errors)
		return
	_error.text = ""
	configuration_submitted.emit(configuration)

func _on_campsite_selected(index: int) -> void:
	if index < 0 or index >= _campsite.item_count:
		return
	_selected_campsite_id = str(_campsite.get_item_metadata(index))
	var profile := CampsiteCatalog.find(_selected_campsite_id)
	_campsite_details.text = profile.tradeoff_summary() if profile != null else ""

func _update_favorites_label() -> void:
	if _favorites.is_empty():
		_favorites_label.text = "Favorite Artists (0/%d): none yet" % RunConfiguration.MAX_FAVORITES
		return
	var lines := PackedStringArray(["Favorite Artists (%d/%d):" % [_favorites.size(), RunConfiguration.MAX_FAVORITES]])
	for favorite in _favorites:
		var genre := _catalog.find_by_id(favorite.genre_id)
		lines.append("• %s — %s" % [favorite.artist_name, genre.display_name if genre else favorite.genre_id])
	_favorites_label.text = "\n".join(lines)
