class_name SchedulePlanner
extends RefCounted
## Read model for browsing the Lineup and identifying desirable overlaps.

const DESIRABLE_AFFINITY := 0.80

static func sets_for_day(lineup: Lineup, festival_day: int) -> Array[FestivalSet]:
	var result: Array[FestivalSet] = []
	var day_index := festival_day - 1
	if day_index < 0 or day_index >= FestivalGenerator.DAY_COUNT:
		return result
	for festival_set in lineup.sets:
		if int(festival_set.start_minute / FestivalTime.MINUTES_PER_DAY) == day_index:
			result.append(festival_set)
	result.sort_custom(func(a: FestivalSet, b: FestivalSet) -> bool:
		if a.start_minute == b.start_minute:
			return a.stage.display_name < b.stage.display_name
		return a.start_minute < b.start_minute)
	return result

static func conflicts(lineup: Lineup) -> Array[ScheduleConflict]:
	var result: Array[ScheduleConflict] = []
	var desirable: Array[FestivalSet] = []
	for festival_set in lineup.sets:
		if festival_set.artist.is_favorite or festival_set.artist.affinity >= DESIRABLE_AFFINITY:
			desirable.append(festival_set)
	for first_index in range(desirable.size()):
		for second_index in range(first_index + 1, desirable.size()):
			var first := desirable[first_index]
			var second := desirable[second_index]
			if first.stage != second.stage and first.overlaps(second):
				result.append(ScheduleConflict.new(first, second))
	return result

static func conflicted_sets(lineup: Lineup) -> Dictionary:
	var result := {}
	for conflict in conflicts(lineup):
		result[conflict.first] = true
		result[conflict.second] = true
	return result

