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

const REAL_SECONDS_PER_GAME_MINUTE := 1.0

var time_scale := 1.0      # fast-forward multiplier (player-controlled later)
var paused := false
var total_minutes := 0.0   # absolute game-minutes since arrival

var _last_whole_minute := 0
var _last_hour := -1
var _last_day := -1

func _ready() -> void:
	_last_hour = FestivalTime.hour(total_minutes)
	_last_day = FestivalTime.day(total_minutes)

func _process(delta: float) -> void:
	if paused:
		return
	var advance := (delta / REAL_SECONDS_PER_GAME_MINUTE) * time_scale
	if advance <= 0.0:
		return
	total_minutes += advance
	time_advanced.emit(advance)
	_emit_boundaries()

func reset() -> void:
	total_minutes = 0.0
	_last_whole_minute = 0
	_last_hour = FestivalTime.hour(0.0)
	_last_day = FestivalTime.day(0.0)

func _emit_boundaries() -> void:
	var whole := int(floor(total_minutes))
	while _last_whole_minute < whole:
		_last_whole_minute += 1
		minute_ticked.emit(_last_whole_minute)
	var h := FestivalTime.hour(total_minutes)
	if h != _last_hour:
		_last_hour = h
		hour_started.emit(h)
	var d := FestivalTime.day(total_minutes)
	if d != _last_day:
		_last_day = d
		day_started.emit(d)
