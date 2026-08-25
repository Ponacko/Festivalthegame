class_name ScoreLedger
extends RefCounted
## Append-only explanation of every point earned during a Run.

var entries: Array[ScoreEntry] = []
var _total := 0.0

func record_attendance(
		festival_set: FestivalSet,
		attended_minutes: float,
		affinity_multiplier: float,
		zone_multiplier: float,
		needs_multiplier: float) -> ScoreEntry:
	if festival_set == null or attended_minutes <= 0.0:
		return null
	var points := attended_minutes * maxf(0.0, affinity_multiplier) \
		* maxf(0.0, zone_multiplier) * maxf(0.0, needs_multiplier)
	if points <= 0.0:
		return null
	if not entries.is_empty():
		var previous := entries[-1]
		if previous.festival_set == festival_set \
				and is_equal_approx(previous.affinity_multiplier, affinity_multiplier) \
				and is_equal_approx(previous.zone_multiplier, zone_multiplier):
			previous.attended_minutes += attended_minutes
			previous.points += points
			previous.needs_multiplier = previous.points / (
				previous.attended_minutes * affinity_multiplier * zone_multiplier)
			_total += points
			return previous
	var entry := ScoreEntry.new(
		festival_set,
		festival_set.artist.name,
		attended_minutes,
		affinity_multiplier,
		zone_multiplier,
		needs_multiplier,
		points)
	_append(entry)
	return entry

func record_bonus(source_name: String, points: float) -> ScoreEntry:
	var normalized_source := source_name.strip_edges()
	if normalized_source.is_empty() or points <= 0.0:
		return null
	var entry := ScoreEntry.new(null, normalized_source, 0.0, 1.0, 1.0, 1.0, points)
	_append(entry)
	return entry

func total() -> float:
	return _total

func attended_minutes_for(festival_set: FestivalSet) -> float:
	var result := 0.0
	for entry in entries:
		if entry.festival_set == festival_set:
			result += entry.attended_minutes
	return result

func _append(entry: ScoreEntry) -> void:
	entries.append(entry)
	_total += entry.points
