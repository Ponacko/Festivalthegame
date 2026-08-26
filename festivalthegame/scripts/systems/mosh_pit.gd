class_name MoshPit
extends RefCounted
## Eligibility and spatial/time window for opt-in Mosh participation.

const ROOT_GENRES := [
	"cc28f5aa-5e19-487c-88e1-e56b022f1fdd", # metal
	"8cc9b280-230b-4a3a-b1e2-8acab0744dd3", # punk
	"055a6e4d-d929-42ac-ba7a-9d063b254ea5", # hardcore punk
]
const GRAPH_RADIUS := 2
const PEAK_START := 0.25
const PEAK_END := 0.75

static func build_eligible_genres(graph: GenreGraph) -> Dictionary:
	var distances := graph.distances_from(PackedStringArray(ROOT_GENRES))
	var result := {}
	for genre_id in distances:
		if int(distances[genre_id]) <= GRAPH_RADIUS:
			result[genre_id] = true
	return result

static func is_available(
		festival_set: FestivalSet,
		world_position: Vector2,
		total_minutes: float,
		eligible_genres: Dictionary) -> bool:
	if festival_set == null or not eligible_genres.has(festival_set.artist.genre_id):
		return false
	if Audience.zone_at(world_position.distance_to(festival_set.stage.position)) != Audience.Zone.FRONT:
		return false
	var duration := festival_set.end_minute - festival_set.start_minute
	var peak_start := festival_set.start_minute + duration * PEAK_START
	var peak_end := festival_set.start_minute + duration * PEAK_END
	return total_minutes >= peak_start and total_minutes <= peak_end
