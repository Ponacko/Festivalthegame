class_name ArtistAffinity
extends RefCounted
## Maps Genre Distance from the player's tastes to an Artist affinity.

const FAVORITE_AFFINITY := 1.0
const SAME_GENRE_AFFINITY := 0.85
const DECAY_PER_EDGE := 0.72
const MIN_AFFINITY := 0.10

var _graph: GenreGraph

func _init(graph: GenreGraph) -> void:
	_graph = graph

func for_artist(artist: Artist, favorites: Array[FavoriteArtistPreference]) -> float:
	for favorite in favorites:
		if artist.is_favorite or artist.name.nocasecmp_to(favorite.artist_name) == 0:
			return FAVORITE_AFFINITY
	var nearest_distance := -1
	for favorite in favorites:
		var candidate := _graph.distance(artist.genre_id, favorite.genre_id)
		if candidate >= 0 and (nearest_distance < 0 or candidate < nearest_distance):
			nearest_distance = candidate
	if nearest_distance < 0:
		return MIN_AFFINITY
	return maxf(MIN_AFFINITY, SAME_GENRE_AFFINITY * pow(DECAY_PER_EDGE, nearest_distance))

