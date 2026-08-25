class_name FestivalTime
extends RefCounted
## Pure, testable helpers that convert an absolute count of festival minutes
## into wall-clock time and Festival Day numbers.
##
## Minute 0 is the moment the player arrives: Day 1 at START_HOUR:00.
## A Festival Day keeps its number through the post-midnight arena hour and the
## overnight phase. The next Day begins when the arena reopens at 11:00.

const START_HOUR := 11
const MINUTES_PER_DAY := 24 * 60
const ARENA_DURATION_MINUTES := 14 * 60
const PLAYABLE_DAYS := 3

static func day(total_minutes: float) -> int:
	return clampi(int(floor(total_minutes / MINUTES_PER_DAY)) + 1, 1, PLAYABLE_DAYS)

static func minute_of_day(total_minutes: float) -> int:
	return int(posmod(int(START_HOUR * 60 + total_minutes), MINUTES_PER_DAY))

static func hour(total_minutes: float) -> int:
	return minute_of_day(total_minutes) / 60

static func minute(total_minutes: float) -> int:
	return minute_of_day(total_minutes) % 60

static func clock_string(total_minutes: float) -> String:
	return "%02d:%02d" % [hour(total_minutes), minute(total_minutes)]

static func festival_day_start(festival_day: int) -> float:
	return float((festival_day - 1) * MINUTES_PER_DAY)

static func arena_close_minute(festival_day: int) -> float:
	return festival_day_start(festival_day) + ARENA_DURATION_MINUTES

static func run_end_minute() -> float:
	return arena_close_minute(PLAYABLE_DAYS)

static func is_arena_open(total_minutes: float) -> bool:
	if total_minutes < 0.0 or total_minutes >= run_end_minute():
		return false
	var festival_day := day(total_minutes)
	return total_minutes >= festival_day_start(festival_day) \
		and total_minutes < arena_close_minute(festival_day)
