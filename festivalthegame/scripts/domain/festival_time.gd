class_name FestivalTime
extends RefCounted
## Pure, testable helpers that convert an absolute count of festival minutes
## into wall-clock time and Festival Day numbers.
##
## Minute 0 is the moment the player arrives: Day 1 at START_HOUR:00.
## Days are plain 24h days for clock arithmetic; the "arena open" window
## (roughly 11:00 to 01:00) is a scheduling concern layered on top later.

const START_HOUR := 11
const MINUTES_PER_DAY := 24 * 60

static func day(total_minutes: float) -> int:
	return int(floor((START_HOUR * 60 + total_minutes) / MINUTES_PER_DAY)) + 1

static func minute_of_day(total_minutes: float) -> int:
	return int(posmod(int(START_HOUR * 60 + total_minutes), MINUTES_PER_DAY))

static func hour(total_minutes: float) -> int:
	return minute_of_day(total_minutes) / 60

static func minute(total_minutes: float) -> int:
	return minute_of_day(total_minutes) % 60

static func clock_string(total_minutes: float) -> String:
	return "%02d:%02d" % [hour(total_minutes), minute(total_minutes)]
