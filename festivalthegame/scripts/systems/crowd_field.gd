class_name CrowdField
extends RefCounted
## Non-blocking crowd pressure around active Sets.

const ZONE_DENSITY := {
	Audience.Zone.NONE: 0.0,
	Audience.Zone.BACK: 0.30,
	Audience.Zone.MID: 0.65,
	Audience.Zone.FRONT: 1.0,
}
const MIN_SPEED_MULTIPLIER := 0.5

static func density(lineup: Lineup, world_position: Vector2, total_minutes: float) -> float:
	if lineup == null:
		return 0.0
	var result := 0.0
	for stage in lineup.stages:
		var festival_set := lineup.active_set_for(stage, total_minutes)
		if festival_set == null:
			continue
		var zone := Audience.zone_at(world_position.distance_to(stage.position))
		result = maxf(result, clampf(festival_set.artist.popularity, 0.0, 1.0) * ZONE_DENSITY[zone])
	return result

static func speed_multiplier(lineup: Lineup, world_position: Vector2, total_minutes: float) -> float:
	return clampf(1.0 / (1.0 + density(lineup, world_position, total_minutes)), MIN_SPEED_MULTIPLIER, 1.0)
