class_name FriendGenerator
extends RefCounted
## Seeded taste profiles and independent, time-feasible personal schedules.

const NAMES := ["Alex", "Billie", "Casey", "Devon"]
const SETS_PER_DAY := 6
const TRAVEL_BUFFER := 20.0

static func generate(
		configuration: RunConfiguration,
		lineup: Lineup,
		grounds: FestivalGrounds,
		graph: GenreGraph,
		seed_value: int) -> Array[FestivalFriend]:
	var result: Array[FestivalFriend] = []
	for friend_index in range(configuration.friend_count):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value ^ ((friend_index + 1) * 0x46524945)
		var friend := FestivalFriend.new()
		friend.id = "friend_%d" % (friend_index + 1)
		friend.display_name = NAMES[friend_index]
		friend.index = friend_index
		friend.camp_position = grounds.camp.position
		var favorite := configuration.favorites[friend_index % configuration.favorites.size()]
		friend.taste_genre_ids.append(favorite.genre_id)
		friend.taste_genre_ids.append(lineup.artists[rng.randi_range(0, lineup.artists.size() - 1)].genre_id)
		friend.schedule = _build_schedule(friend, lineup, graph.distances_from(friend.taste_genre_ids), rng)
		result.append(friend)
	return result

static func _build_schedule(
		friend: FestivalFriend,
		lineup: Lineup,
		distances: Dictionary,
		rng: RandomNumberGenerator) -> Array[FestivalSet]:
	var result: Array[FestivalSet] = []
	for day in range(1, FestivalTime.PLAYABLE_DAYS + 1):
		var candidates := SchedulePlanner.sets_for_day(lineup, day)
		var desirability := {}
		for festival_set in candidates:
			var distance := int(distances.get(festival_set.artist.genre_id, -1))
			desirability[festival_set] = ArtistAffinity.from_distance(distance) + rng.randf_range(0.0, 0.25)
		candidates.sort_custom(func(a: FestivalSet, b: FestivalSet) -> bool:
			return float(desirability[a]) > float(desirability[b]))
		var selected: Array[FestivalSet] = []
		for candidate in candidates:
			if selected.size() >= SETS_PER_DAY:
				break
			var fits := true
			for existing in selected:
				if candidate.start_minute < existing.end_minute + TRAVEL_BUFFER \
						and existing.start_minute < candidate.end_minute + TRAVEL_BUFFER:
					fits = false
					break
			if fits:
				selected.append(candidate)
		selected.sort_custom(func(a: FestivalSet, b: FestivalSet) -> bool:
			return a.start_minute < b.start_minute)
		result.append_array(selected)
	return result
