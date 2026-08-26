class_name FinalResult
extends RefCounted
## Immutable, explainable outcome of one completed Run.

const WAR_STORY_TYPES := [
	"collapse", "bladder_accident", "food_poisoning_onset", "food_poisoning_urgent",
	"injury", "injury_treated", "night_party", "night_summary",
]

var run_seed: int
var configuration_summary: String
var total_score: float
var theoretical_maximum: float
var percentage: float
var completed_at_unix: int
var breakdown: Array[Dictionary] = []
var war_stories := PackedStringArray()

static func build(
		seed_value: int,
		configuration: String,
		ledger: ScoreLedger,
		maximum: float,
		events: Array[RunEvent],
		completed_at := -1) -> FinalResult:
	var result := FinalResult.new()
	result.run_seed = seed_value
	result.configuration_summary = configuration
	result.total_score = ledger.total()
	result.theoretical_maximum = maxf(maximum, result.total_score)
	result.percentage = 0.0 if result.theoretical_maximum <= 0.0 else result.total_score / result.theoretical_maximum * 100.0
	result.completed_at_unix = completed_at if completed_at >= 0 else int(Time.get_unix_time_from_system())
	for entry in ledger.entries:
		result.breakdown.append({
			"source": entry.source_name,
			"minutes": entry.attended_minutes,
			"zone": entry.audience_zone,
			"points": entry.points,
			"bonus": entry.festival_set == null,
		})
	for event in events:
		if WAR_STORY_TYPES.has(event.event_type):
			result.war_stories.append("%s — %s" % [event.event_type.replace("_", " ").capitalize(), event.detail])
	return result

func breakdown_total() -> float:
	var total := 0.0
	for item in breakdown:
		total += float(item["points"])
	return total

func breakdown_text() -> String:
	var lines := PackedStringArray()
	for item in breakdown:
		lines.append("%s%s — %.0f min — %s — %.1f pts" % [
			"BONUS: " if item["bonus"] else "",
			item["source"], item["minutes"], item["zone"], item["points"]])
	return "\n".join(lines)

func high_score_entry() -> Dictionary:
	return {
		"run_seed": run_seed,
		"configuration": configuration_summary,
		"score": total_score,
		"maximum": theoretical_maximum,
		"percentage": percentage,
		"completed_at": completed_at_unix,
	}
