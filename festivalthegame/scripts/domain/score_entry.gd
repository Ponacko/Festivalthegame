class_name ScoreEntry
extends RefCounted
## One explainable, monotonic increase in Enjoyment Score.

var festival_set: FestivalSet
var source_name: String
var attended_minutes: float
var affinity_multiplier: float
var zone_multiplier: float
var needs_multiplier: float
var points: float
var recorded_at := -1.0
var audience_zone := "—"

func _init(
		p_set: FestivalSet,
		p_source_name: String,
		p_attended_minutes: float,
		p_affinity: float,
		p_zone: float,
		p_needs: float,
		p_points: float) -> void:
	festival_set = p_set
	source_name = p_source_name
	attended_minutes = p_attended_minutes
	affinity_multiplier = p_affinity
	zone_multiplier = p_zone
	needs_multiplier = p_needs
	points = p_points
