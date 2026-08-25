class_name TheoreticalMaximum
extends RefCounted
## Optimistic Festival ceiling: best active Set at every instant, from the
## Front with thriving Needs, while ignoring travel and resource costs.

static func calculate(lineup: Lineup) -> float:
	if lineup == null or lineup.sets.is_empty():
		return 0.0
	var boundaries: Array[float] = []
	for festival_set in lineup.sets:
		boundaries.append(festival_set.start_minute)
		boundaries.append(festival_set.end_minute)
	boundaries.sort()
	var affinity_minutes := 0.0
	for index in range(1, boundaries.size()):
		var interval_start := boundaries[index - 1]
		var interval_end := boundaries[index]
		if interval_end <= interval_start:
			continue
		var sample := (interval_start + interval_end) * 0.5
		var best_affinity := 0.0
		for festival_set in lineup.sets:
			if festival_set.is_active(sample):
				var affinity := 1.0 if festival_set.artist.is_favorite else festival_set.artist.affinity
				best_affinity = maxf(best_affinity, affinity)
		affinity_minutes += best_affinity * (interval_end - interval_start)
	return affinity_minutes * Audience.multiplier(Audience.Zone.FRONT) * Needs.MULT_MAX
