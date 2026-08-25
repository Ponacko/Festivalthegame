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
