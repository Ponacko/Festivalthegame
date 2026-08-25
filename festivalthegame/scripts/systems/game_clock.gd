extends Node
## Global festival clock (autoload "Clock").
##
## Advances game-time while unpaused at 1 real second = 1 game minute (scaled
## by time_scale for fast-forward). Emits a continuous time_advanced signal for
## per-frame effects like Need decay, plus discrete boundary signals for events.

signal time_advanced(minutes: float)     # fractional game-minutes, every frame
signal minute_ticked(total_minutes: int) # each whole game-minute crossed
signal hour_started(hour: int)
signal day_started(day: int)
signal arena_closed(day: int)
signal night_started(day: int)
signal morning_started(day: int)
signal run_completed

const REAL_SECONDS_PER_GAME_MINUTE := 1.0

var time_scale := 1.0      # fast-forward multiplier (player-controlled later)
var paused := false
var total_minutes := 0.0   # absolute game-minutes since arrival

var _last_whole_minute := 0
var _complete := false

func _process(delta: float) -> void:
	advance(delta)

## Advances by real seconds. Every simulation system receives the same scaled
## game-minute delta through time_advanced.
func advance(real_seconds: float) -> void:
	if paused or _complete:
		return
	var game_minutes := (real_seconds / REAL_SECONDS_PER_GAME_MINUTE) * time_scale
	_advance_game_minutes(game_minutes)

## Applies a fixed simulation-time cost independent of the selected speed.
func advance_game_minutes(game_minutes: float) -> void:
	if _complete:
		return
	_advance_game_minutes(game_minutes)

func _advance_game_minutes(game_minutes: float) -> void:
	if game_minutes <= 0.0:
		return
	var previous := total_minutes
	total_minutes = minf(total_minutes + game_minutes, FestivalTime.run_end_minute())
	var actual_advance := total_minutes - previous
	if actual_advance <= 0.0:
		return
	time_advanced.emit(actual_advance)
	_emit_boundaries(previous, total_minutes)

func set_paused(value: bool) -> void:
	if not _complete:
		paused = value

func toggle_paused() -> void:
	set_paused(not paused)

func set_time_scale(value: float) -> void:
	time_scale = clampf(value, 1.0, 64.0)

func cycle_time_scale(direction := 1) -> void:
	var choices := [1.0, 2.0, 4.0, 8.0]
	var current_index := 0
	for index in range(choices.size()):
		if choices[index] >= time_scale:
			current_index = index
			break
	current_index = posmod(current_index + direction, choices.size())
	set_time_scale(choices[current_index])

func is_complete() -> bool:
	return _complete

func reset() -> void:
	total_minutes = 0.0
	time_scale = 1.0
	paused = false
	_complete = false
	_last_whole_minute = 0

func _emit_boundaries(previous: float, current: float) -> void:
	var whole := int(floor(total_minutes))
	while _last_whole_minute < whole:
		_last_whole_minute += 1
		minute_ticked.emit(_last_whole_minute)
		if FestivalTime.minute(float(_last_whole_minute)) == 0:
			hour_started.emit(FestivalTime.hour(float(_last_whole_minute)))
	for festival_day in range(1, FestivalTime.PLAYABLE_DAYS + 1):
		if festival_day > 1:
			var morning := FestivalTime.festival_day_start(festival_day)
			if previous < morning and current >= morning:
				morning_started.emit(festival_day)
				day_started.emit(festival_day)
		var close := FestivalTime.arena_close_minute(festival_day)
		if previous < close and current >= close:
			arena_closed.emit(festival_day)
			night_started.emit(festival_day)
	if current >= FestivalTime.run_end_minute() and not _complete:
		_complete = true
		paused = true
		run_completed.emit()
