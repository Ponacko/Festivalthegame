class_name TipsyState
extends RefCounted
## Bounded deterministic alcohol effects and deferred next-day cost.

const MAX_LEVEL := 1.0
const MAX_DURATION_MINUTES := 4.0 * 60.0
const MAX_WOBBLE_RADIANS := 0.18
const BLADDER_DRAIN_PER_LEVEL_MINUTE := 0.22
const GAIN_BONUS_AT_MAX := 0.35
const OVERINDULGENCE_LEVEL := 0.65
const MAX_NEXT_DAY_ENERGY_PENALTY := 50.0

var level := 0.0
var remaining_minutes := 0.0
var next_day_energy_penalty := 0.0

func consume(item: AlcoholItem) -> void:
	level = clampf(level + item.potency, 0.0, MAX_LEVEL)
	remaining_minutes = minf(
		maxf(remaining_minutes, item.duration_minutes) + item.duration_minutes * 0.25,
		MAX_DURATION_MINUTES)
	if level > OVERINDULGENCE_LEVEL:
		next_day_energy_penalty = minf(
			next_day_energy_penalty + item.potency * 20.0,
			MAX_NEXT_DAY_ENERGY_PENALTY)

func advance(minutes: float, needs: Needs) -> bool:
	if not is_active() or minutes <= 0.0:
		return false
	var active_step := minf(minutes, remaining_minutes)
	needs.adjust(Needs.Kind.BLADDER, -BLADDER_DRAIN_PER_LEVEL_MINUTE * level * active_step)
	remaining_minutes = maxf(0.0, remaining_minutes - minutes)
	if remaining_minutes <= 0.0001:
		remaining_minutes = 0.0
		level = 0.0
		return true
	return false

func gain_multiplier() -> float:
	return 1.0 + level * GAIN_BONUS_AT_MAX

func movement_direction(base_direction: Vector2, total_minutes: float) -> Vector2:
	if not is_active() or base_direction.is_zero_approx():
		return base_direction.normalized()
	var wobble := sin(total_minutes * 2.3 + level * 1.7) * MAX_WOBBLE_RADIANS * level
	return base_direction.normalized().rotated(wobble)

func consume_next_day_energy_penalty() -> float:
	var result := next_day_energy_penalty
	next_day_energy_penalty = 0.0
	return result

func is_active() -> bool:
	return level > 0.0 and remaining_minutes > 0.0
