class_name FestivalFriend
extends RefCounted
## One generated Friend with tastes, personal Set choices, and shared camp.

var id: String
var display_name: String
var index: int
var taste_genre_ids := PackedStringArray()
var schedule: Array[FestivalSet] = []
var camp_position: Vector2
var meet_destination: FestivalPoint
var meet_until := -1.0

func current_set(total_minutes: float) -> FestivalSet:
	for festival_set in schedule:
		if festival_set.is_active(total_minutes):
			return festival_set
	return null

func next_set_after(total_minutes: float) -> FestivalSet:
	for festival_set in schedule:
		if festival_set.start_minute > total_minutes:
			return festival_set
	return null

func clear_meet_request() -> void:
	meet_destination = null
	meet_until = -1.0

func destination_kind_at(total_minutes: float, grounds: FestivalGrounds) -> FestivalPoint.Kind:
	if current_set(total_minutes) != null:
		return FestivalPoint.Kind.STAGE
	if meet_destination != null and total_minutes < meet_until:
		return meet_destination.kind
	var phase := posmod(int(total_minutes / 30.0) + index * 2, 12)
	if phase == 3:
		return FestivalPoint.Kind.WATER
	if phase == 8:
		return FestivalPoint.Kind.TOILET
	return FestivalPoint.Kind.CAMP

func destination_position_at(total_minutes: float, grounds: FestivalGrounds) -> Vector2:
	var festival_set := current_set(total_minutes)
	if festival_set != null:
		return festival_set.stage.position
	if meet_destination != null and total_minutes < meet_until:
		return meet_destination.position
	var kind := destination_kind_at(total_minutes, grounds)
	var destinations := grounds.points_of_kind(kind)
	if destinations.is_empty():
		return camp_position
	return destinations[index % destinations.size()].position

func current_activity(total_minutes: float, grounds: FestivalGrounds) -> String:
	var festival_set := current_set(total_minutes)
	if festival_set != null:
		return "Watching %s" % festival_set.artist.name
	if meet_destination != null and total_minutes < meet_until:
		return "Meeting at %s" % meet_destination.display_name
	var kind := destination_kind_at(total_minutes, grounds)
	if kind == FestivalPoint.Kind.CAMP:
		return "Relaxing at camp"
	return "Visiting %s" % FestivalPoint.kind_name(kind)

func current_location_name(total_minutes: float, grounds: FestivalGrounds) -> String:
	var festival_set := current_set(total_minutes)
	if festival_set != null:
		return festival_set.stage.display_name
	if meet_destination != null and total_minutes < meet_until:
		return meet_destination.display_name
	var position := destination_position_at(total_minutes, grounds)
	for point in grounds.points:
		if point.position == position:
			return point.display_name
	return "Camp"

func next_set_summary(total_minutes: float) -> String:
	var festival_set := next_set_after(total_minutes)
	if festival_set == null:
		return "No more Sets planned"
	return "%s at %s (%s)" % [
		festival_set.artist.name,
		festival_set.stage.display_name,
		FestivalTime.clock_string(festival_set.start_minute),
	]

func schedule_signature() -> String:
	var parts := PackedStringArray()
	for festival_set in schedule:
		parts.append("%s@%.1f" % [festival_set.artist.name, festival_set.start_minute])
	return "|".join(parts)

func average_scheduled_affinity(graph: GenreGraph) -> float:
	if schedule.is_empty():
		return 0.0
	var distances := graph.distances_from(taste_genre_ids)
	var total := 0.0
	for festival_set in schedule:
		total += ArtistAffinity.from_distance(int(distances.get(festival_set.artist.genre_id, -1)))
	return total / schedule.size()

static func group_signature(friends: Array[FestivalFriend]) -> String:
	var parts := PackedStringArray()
	for friend in friends:
		parts.append("%s:%s:%s" % [friend.id, ",".join(friend.taste_genre_ids), friend.schedule_signature()])
	return "\n".join(parts)
