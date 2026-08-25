class_name FestivalGenerator
extends RefCounted
## Seeded procedural generation for one complete Festival Lineup.

const DAY_COUNT := 3
const ARENA_MINUTES := 14.0 * 60.0
const SETS_PER_STAGE_DAY := 9
const MIN_CHANGEOVER := 15.0
const MAX_CHANGEOVER := 20.0
const SET_DURATIONS := [45.0, 60.0, 75.0]

const NAME_PREFIXES := [
	"Amber", "Arc", "Astral", "Black", "Broken", "Chrome", "Crimson", "Crystal",
	"Electric", "Feral", "Glass", "Golden", "Hollow", "Ivory", "Last", "Lost",
	"Lunar", "Midnight", "Neon", "Northern", "Paper", "Phantom", "Quiet", "Red",
	"Royal", "Silver", "Static", "Velvet", "Wild", "Young",
]
const NAME_NOUNS := [
	"Atlas", "Bloom", "Casket", "Choir", "Circuit", "Comets", "Crown", "Dancers",
	"Dream", "Echo", "Engine", "Fires", "Ghosts", "Harbour", "Hearts", "Hotel",
	"Knives", "Lanterns", "Machine", "Mirrors", "Noise", "Parade", "Pilots", "Ritual",
	"Saints", "Signal", "Sparks", "Tides", "Valley", "Wolves",
]

static func generate(
		configuration: RunConfiguration,
		seed_value: int,
		catalog: GenreCatalog,
		graph: GenreGraph) -> Lineup:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var lineup := Lineup.new()
	lineup.stages = _build_stages()
	var slots := _build_slots(lineup.stages, rng)
	var pools := _build_genre_pools(configuration, catalog, graph)
	var used_names := {}
	for favorite in configuration.favorites:
		used_names[favorite.artist_name.to_lower()] = true
	var affinity := ArtistAffinity.new(graph)
	var favorite_slots := _favorite_slot_map(configuration.favorites.size(), slots.size())
	var nonfavorite_index := 0

	for index in range(slots.size()):
		var slot: Dictionary = slots[index]
		var stage: Stage = slot.stage
		var artist: Artist
		if favorite_slots.has(index):
			var favorite: FavoriteArtistPreference = configuration.favorites[favorite_slots[index]]
			artist = Artist.new(favorite.artist_name, favorite.genre_id, _popularity_for(stage, rng), true)
		else:
			var forced_genre: GenreEntry = null
			if configuration.favorites.size() == 1 and index == SETS_PER_STAGE_DAY:
				forced_genre = catalog.find_by_id(configuration.favorites[0].genre_id)
			var genre := forced_genre if forced_genre != null else _choose_genre(nonfavorite_index, pools, rng)
			artist = Artist.new(_unique_artist_name(used_names, rng), genre.id, _popularity_for(stage, rng))
			nonfavorite_index += 1
		used_names[artist.name.to_lower()] = true
		artist.affinity = affinity.for_artist(artist, configuration.favorites)
		lineup.artists.append(artist)
		lineup.sets.append(FestivalSet.new(artist, stage, slot.start, slot.end))
	return lineup

static func _favorite_slot_map(favorite_count: int, slot_count: int) -> Dictionary:
	var result := {}
	var preferred := [0, SETS_PER_STAGE_DAY, SETS_PER_STAGE_DAY * 2, SETS_PER_STAGE_DAY * 3]
	var favorite_index := 0
	for slot_index in preferred:
		if favorite_index >= favorite_count or slot_index >= slot_count:
			break
		result[slot_index] = favorite_index
		favorite_index += 1
	var slot_index := 0
	while favorite_index < favorite_count and slot_index < slot_count:
		if not result.has(slot_index):
			result[slot_index] = favorite_index
			favorite_index += 1
		slot_index += 1
	return result

static func _build_stages() -> Array[Stage]:
	return [
		Stage.new("main", "Main Stage", Vector2(-650, -420), Stage.Size.MAIN),
		Stage.new("north", "North Stage", Vector2(650, -420), Stage.Size.MID),
		Stage.new("field", "Field Stage", Vector2(520, 520), Stage.Size.MID),
		Stage.new("tent", "The Tent", Vector2(-560, 520), Stage.Size.SMALL),
	]

static func _build_slots(stages: Array[Stage], rng: RandomNumberGenerator) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for day_index in range(DAY_COUNT):
		var day_start := float(day_index * FestivalTime.MINUTES_PER_DAY)
		for stage in stages:
			var cursor := day_start
			for slot_index in range(SETS_PER_STAGE_DAY):
				var duration: float = SET_DURATIONS[rng.randi_range(0, SET_DURATIONS.size() - 1)]
				slots.append({"stage": stage, "start": cursor, "end": cursor + duration})
				if slot_index < SETS_PER_STAGE_DAY - 1:
					cursor += duration + rng.randf_range(MIN_CHANGEOVER, MAX_CHANGEOVER)
	return slots

static func _build_genre_pools(
		configuration: RunConfiguration,
		catalog: GenreCatalog,
		graph: GenreGraph) -> Dictionary:
	var favorite_ids := PackedStringArray()
	for favorite in configuration.favorites:
		favorite_ids.append(favorite.genre_id)
	var distances := graph.distances_from(favorite_ids)
	var all := catalog.all_entries()
	var taste: Array[GenreEntry] = []
	var floor: Array[GenreEntry] = []
	for genre in all:
		var distance: int = distances.get(genre.id, -1)
		if distance >= 0 and distance <= 2:
			taste.append(genre)
		if ArtistAffinity.from_distance(distance) <= ArtistAffinity.MIN_AFFINITY:
			floor.append(genre)
	if taste.is_empty():
		taste = all.duplicate()
	if floor.is_empty():
		floor = all.duplicate()
	return {"all": all, "taste": taste, "floor": floor}

static func _choose_genre(index: int, pools: Dictionary, rng: RandomNumberGenerator) -> GenreEntry:
	var pool: Array[GenreEntry]
	if index % 10 == 0:
		pool = pools.floor
	elif rng.randf() < 0.82:
		pool = pools.taste
	else:
		pool = pools.all
	return pool[rng.randi_range(0, pool.size() - 1)]

static func _popularity_for(stage: Stage, rng: RandomNumberGenerator) -> float:
	match stage.size:
		Stage.Size.MAIN:
			return rng.randf_range(0.75, 1.0)
		Stage.Size.MID:
			return rng.randf_range(0.35, 0.849)
		Stage.Size.SMALL:
			return rng.randf_range(0.05, 0.499)
	return 0.5

static func _unique_artist_name(used_names: Dictionary, rng: RandomNumberGenerator) -> String:
	for attempt in range(1000):
		var candidate: String = "%s %s" % [
			NAME_PREFIXES[rng.randi_range(0, NAME_PREFIXES.size() - 1)],
			NAME_NOUNS[rng.randi_range(0, NAME_NOUNS.size() - 1)],
		]
		if not used_names.has(candidate.to_lower()):
			return candidate
	return "Festival Artist %d" % used_names.size()
