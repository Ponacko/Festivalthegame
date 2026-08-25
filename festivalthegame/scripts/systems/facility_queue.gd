class_name FacilityQueue
extends RefCounted
## Timed, interruptible water/toilet interaction.

const MAX_QUEUE_MINUTES := 12.0
const MOOD_LOSS_PER_MINUTE := 0.18

var facility: FestivalPoint
var total_minutes := 0.0
var remaining_minutes := 0.0
var _active := false

static func duration_for(kind: FestivalPoint.Kind, nearby_density: float) -> float:
	var density := clampf(nearby_density, 0.0, 1.0)
	match kind:
		FestivalPoint.Kind.WATER:
			return minf(2.0 + density * 6.0, MAX_QUEUE_MINUTES)
		FestivalPoint.Kind.TOILET:
			return minf(4.0 + density * 8.0, MAX_QUEUE_MINUTES)
	return 0.0

func start(point: FestivalPoint, nearby_density: float) -> bool:
	if _active or point == null:
		return false
	var duration := duration_for(point.kind, nearby_density)
	if duration <= 0.0:
		return false
	facility = point
	total_minutes = duration
	remaining_minutes = duration
	_active = true
	return true

func advance(minutes: float, needs: Needs) -> String:
	if not _active or minutes <= 0.0:
		return ""
	var waited := minf(minutes, remaining_minutes)
	needs.adjust(Needs.Kind.MOOD, -MOOD_LOSS_PER_MINUTE * waited)
	remaining_minutes = maxf(0.0, remaining_minutes - minutes)
	if remaining_minutes > 0.0001:
		return ""
	remaining_minutes = 0.0
	_active = false
	if facility.kind == FestivalPoint.Kind.WATER:
		needs.adjust(Needs.Kind.THIRST, 55.0)
		needs.adjust(Needs.Kind.BLADDER, -18.0)
		return "Water collected — Thirst restored."
	if facility.kind == FestivalPoint.Kind.TOILET:
		needs.adjust(Needs.Kind.BLADDER, Needs.MAX)
		return "Toilet visit complete — Bladder restored."
	return "Queue complete."

func interrupt() -> String:
	if not _active:
		return ""
	_active = false
	remaining_minutes = 0.0
	return "You left the %s Queue before service." % facility.display_name

func is_active() -> bool:
	return _active
