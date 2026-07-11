class_name Artist
extends RefCounted
## A performer in the Lineup.
##
## `affinity` is the base Enjoyment earned per game-minute when watched from the
## Back zone with neutral needs (1.0 = Favorite Artist, down to a 0.10 floor).
## In slice 2 it is set directly; later it will be derived from MusicBrainz
## genre-graph distance between `genre` and the player's tastes (see ADR 0001).

var name: String
var genre: String
var popularity: float   # 0..1; will drive Stage size + crowd density
var is_favorite: bool
var affinity: float     # 0.10 .. 1.0

func _init(p_name := "", p_genre := "", p_popularity := 0.5, p_favorite := false, p_affinity := 0.1) -> void:
	name = p_name
	genre = p_genre
	popularity = p_popularity
	is_favorite = p_favorite
	affinity = p_affinity
