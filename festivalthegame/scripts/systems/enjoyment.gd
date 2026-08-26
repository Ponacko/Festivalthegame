extends Node
## Drives the core equation. Each frame it works out which active Set (if any)
## the player is attending and in which Audience Zone, then accrues Enjoyment
## Score per game-minute:
##
##   points_per_minute = artist.affinity × zone_multiplier × needs_multiplier
##
## The readout fields are polled by the HUD.

@export var player_path: NodePath

var current_stage: Stage = null
var current_zone := Audience.Zone.NONE
var current_rate := 0.0   # Enjoyment points per game-minute, right now

var _player: Node2D

func _ready() -> void:
	add_to_group("enjoyment")
	_player = get_node_or_null(player_path)
	Clock.time_advanced.connect(_on_time_advanced)

func _process(_delta: float) -> void:
	_evaluate()  # keep the readout fresh even while paused

func _on_time_advanced(minutes: float) -> void:
	if _player != null:
		Game.advance_mosh(minutes, _player.global_position)
	_score_attendance(Clock.total_minutes - minutes, Clock.total_minutes)
	_evaluate()

func _score_attendance(interval_start: float, interval_end: float) -> void:
	if Game.is_action_locked() or _player == null or Game.lineup == null or Game.needs == null:
		return
	var needs_mult := Game.needs.enjoyment_multiplier()
	var boundaries: Array[float] = [interval_start, interval_end]
	for festival_set in Game.lineup.sets:
		if festival_set.end_minute <= interval_start or festival_set.start_minute >= interval_end:
			continue
		var zone := Audience.zone_at(_player.global_position.distance_to(festival_set.stage.position))
		if zone != Audience.Zone.NONE:
			boundaries.append(maxf(interval_start, festival_set.start_minute))
			boundaries.append(minf(interval_end, festival_set.end_minute))
	boundaries.sort()
	for index in range(1, boundaries.size()):
		var segment_start := boundaries[index - 1]
		var segment_end := boundaries[index]
		if segment_end <= segment_start:
			continue
		var sample := (segment_start + segment_end) * 0.5
		var best_set: FestivalSet = null
		var best_zone := Audience.Zone.NONE
		var best_rate := 0.0
		for festival_set in Game.lineup.sets:
			if not festival_set.is_active(sample):
				continue
			var zone := Audience.zone_at(_player.global_position.distance_to(festival_set.stage.position))
			var rate := festival_set.artist.affinity * Audience.multiplier(zone) * needs_mult
			if rate > best_rate:
				best_set = festival_set
				best_zone = zone
				best_rate = rate
		if best_set != null:
			Game.record_attendance(
				best_set,
				segment_end - segment_start,
				best_set.artist.affinity,
				Audience.multiplier(best_zone),
				needs_mult)

func _evaluate() -> void:
	current_stage = null
	current_zone = Audience.Zone.NONE
	current_rate = 0.0
	if _player == null or Game.lineup == null or Game.needs == null:
		return

	var needs_mult := Game.needs.enjoyment_multiplier()
	var best_rate := 0.0
	for stage in Game.lineup.stages:
		var s := Game.lineup.active_set_for(stage, Clock.total_minutes)
		if s == null:
			continue
		var dist := _player.global_position.distance_to(stage.position)
		var zone := Audience.zone_at(dist)
		if zone == Audience.Zone.NONE:
			continue
		var rate := s.artist.affinity * Audience.multiplier(zone) * needs_mult
		if rate > best_rate:
			best_rate = rate
			current_stage = stage
			current_zone = zone
			current_rate = rate
