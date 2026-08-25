class_name Lineup
extends RefCounted
## The Festival's Stages, Artists, and scheduled Sets. The procedural generator
## replaces build_demo() in a later slice.

var stages: Array[Stage] = []
var artists: Array[Artist] = []
var sets: Array[FestivalSet] = []

func active_set_for(stage: Stage, total_minutes: float) -> FestivalSet:
	for s in sets:
		if s.stage == stage and s.is_active(total_minutes):
			return s
	return null

static func build_demo(configuration: RunConfiguration = null, graph: GenreGraph = null) -> Lineup:
	var lu := Lineup.new()
	if configuration == null:
		configuration = RunConfiguration.new()
		configuration.add_favorite("Your Favourite", "cc28f5aa-5e19-487c-88e1-e56b022f1fdd")
	if graph == null:
		graph = GenreGraph.load_bundled()

	var main_stage := Stage.new("main", "Main Stage", Vector2(-600, -400))
	var tent := Stage.new("tent", "The Tent", Vector2(700, -200))
	var field := Stage.new("field", "Field Stage", Vector2(400, 500))
	lu.stages = [main_stage, tent, field]

	var first_favorite: FavoriteArtistPreference = configuration.favorites[0]
	var headliner := Artist.new(first_favorite.artist_name, first_favorite.genre_id, 0.95, true)
	var synth := Artist.new("Neon Casket", "988e91a3-3341-416d-b7f8-7dbef6848dac", 0.6)
	var punks := Artist.new("The Landfills", "bd7e1d40-43b1-4ba5-97b3-05b891466962", 0.7)
	lu.artists = [headliner, synth, punks]
	var affinity := ArtistAffinity.new(graph)
	for artist in lu.artists:
		artist.affinity = affinity.for_artist(artist, configuration.favorites)

	lu.sets = [
		FestivalSet.new(headliner, main_stage, 0.0, 90.0),
		FestivalSet.new(synth, tent, 0.0, 120.0),
		FestivalSet.new(punks, field, 30.0, 150.0),
	]
	return lu
