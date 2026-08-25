class_name FavoriteArtistPreference
extends RefCounted
## One player-declared Favorite Artist and its manually selected Genre.

var artist_name: String
var genre_id: String

func _init(p_artist_name := "", p_genre_id := "") -> void:
	artist_name = p_artist_name.strip_edges()
	genre_id = p_genre_id.strip_edges()

