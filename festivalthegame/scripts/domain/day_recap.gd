class_name DayRecap
extends RefCounted
## Durable projection of ledger entries and Run events for one completed day.

var day: int
var attended_sets: Array[ScoreEntry] = []
var bonuses: Array[ScoreEntry] = []
var events: Array[RunEvent] = []
var budget_spent := 0.0
var ending_needs := {}

static func build(
		festival_day: int,
		ledger: ScoreLedger,
		run_events: Array[RunEvent],
		spent: float,
		needs: Needs) -> DayRecap:
	var recap := DayRecap.new()
	recap.day = festival_day
	var start := FestivalTime.festival_day_start(festival_day)
	var finish := FestivalTime.festival_day_start(festival_day + 1)
	for entry in ledger.entries:
		if entry.recorded_at < start or entry.recorded_at >= finish:
			continue
		if entry.festival_set == null:
			recap.bonuses.append(entry)
		else:
			recap.attended_sets.append(entry)
	for event in run_events:
		if event.total_minutes >= start and event.total_minutes <= finish:
			recap.events.append(event)
	recap.budget_spent = maxf(0.0, spent)
	for kind in Needs.ALL:
		recap.ending_needs[kind] = needs.get_value(kind)
	return recap

func text() -> String:
	var lines := PackedStringArray(["Festival Day %d recap" % day, ""])
	if attended_sets.is_empty():
		lines.append("No Sets attended.")
	else:
		lines.append("SETS")
		for entry in attended_sets:
			lines.append("%s — %.0f min — %s — %.1f pts" % [
				entry.source_name, entry.attended_minutes, entry.audience_zone, entry.points])
	if not bonuses.is_empty():
		lines.append("BONUSES")
		for entry in bonuses:
			lines.append("%s — +%.1f pts" % [entry.source_name, entry.points])
	lines.append("Budget spent: €%.2f" % budget_spent)
	var need_parts := PackedStringArray()
	for kind in Needs.ALL:
		need_parts.append("%s %.0f" % [Needs.NAMES[kind], ending_needs.get(kind, 0.0)])
	lines.append("Ending Needs: %s" % " • ".join(need_parts))
	if not events.is_empty():
		lines.append("MOMENTS")
		for event in events:
			lines.append("%s — %s" % [event.event_type.replace("_", " ").capitalize(), event.detail])
	return "\n".join(lines)
