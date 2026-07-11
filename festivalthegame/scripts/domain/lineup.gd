class_name Lineup
extends RefCounted
## The Festival's Stages, Artists, and scheduled Sets. Slice 2 uses a small
## hand-authored demo; the procedural generator (with injected Schedule
## Conflicts) replaces build_demo() in a later slice.

var stages: Array[Stage] = []
var artists: Array[Artist] = []
var sets: Array[FestivalSet] = []

func active_set_for(stage: Stage, total_minutes: float) -> FestivalSet:
	for s in sets:
		if s.stage == stage and s.is_active(total_minutes):
			return s
	return null

static func build_demo() -> Lineup:
	var lu := Lineup.new()

	var main_stage := Stage.new("main", "Main Stage", Vector2(-600, -400))
	var tent := Stage.new("tent", "The Tent", Vector2(700, -200))
	var field := Stage.new("field", "Field Stage", Vector2(400, 500))
	lu.stages = [main_stage, tent, field]

	# affinity: 1.0 = favorite; others are placeholders until the genre graph.
	var headliner := Artist.new("Your Favourite", "metal", 0.95, true, 1.0)
	var synth := Artist.new("Neon Casket", "synthpop", 0.6, false, 0.4)
	var punks := Artist.new("The Landfills", "punk", 0.7, false, 0.7)
	lu.artists = [headliner, synth, punks]

	lu.sets = [
		FestivalSet.new(headliner, main_stage, 0.0, 90.0),
		FestivalSet.new(synth, tent, 0.0, 120.0),
		FestivalSet.new(punks, field, 30.0, 150.0),
	]
	return lu
