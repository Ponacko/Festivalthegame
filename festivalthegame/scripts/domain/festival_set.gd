class_name FestivalSet
extends RefCounted
## One Set: an Artist performing on a Stage over a scheduled window.
## (Named FestivalSet to avoid confusion with the `set` keyword; it is the
## domain term "Set".) Times are absolute game-minutes from arrival.

var artist: Artist
var stage: Stage
var start_minute: float
var end_minute: float

func _init(p_artist: Artist = null, p_stage: Stage = null, p_start := 0.0, p_end := 0.0) -> void:
	artist = p_artist
	stage = p_stage
	start_minute = p_start
	end_minute = p_end

func is_active(total_minutes: float) -> bool:
	return total_minutes >= start_minute and total_minutes < end_minute
