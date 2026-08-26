class_name MoshState
extends RefCounted
## Opt-in Mosh participation and persistent treatable Injury.

const BONUS_PER_MINUTE := 0.30
const MOOD_GAIN_PER_MINUTE := 0.35
const ENERGY_DRAIN_PER_MINUTE := 0.55
const DEFAULT_INJURY_RISK_PER_MINUTE := 0.025
const INJURY_MOOD_PENALTY := 22.0

var active_set: FestivalSet
var injured := false
var attended_minutes := 0.0
var risk_per_minute := DEFAULT_INJURY_RISK_PER_MINUTE
var _risk_minute_accumulator := 0.0

func join(festival_set: FestivalSet) -> bool:
	if festival_set == null or injured:
		return false
	active_set = festival_set
	attended_minutes = 0.0
	_risk_minute_accumulator = 0.0
	return true

func leave() -> void:
	active_set = null
	_risk_minute_accumulator = 0.0

func advance(
		minutes: float,
		needs: Needs,
		rng: RandomNumberGenerator,
		risk_override := -1.0) -> Dictionary:
	if not is_active() or minutes <= 0.0:
		return {"bonus_points": 0.0, "injured_now": false}
	attended_minutes += minutes
	needs.adjust(Needs.Kind.MOOD, MOOD_GAIN_PER_MINUTE * minutes)
	needs.adjust(Needs.Kind.ENERGY, -ENERGY_DRAIN_PER_MINUTE * minutes)
	var injured_now := false
	var risk := risk_per_minute if risk_override < 0.0 else risk_override
	_risk_minute_accumulator += minutes
	while _risk_minute_accumulator >= 1.0 and not injured:
		_risk_minute_accumulator -= 1.0
		if rng.randf() < clampf(risk, 0.0, 1.0):
			injured = true
			injured_now = true
			needs.set_mood_penalty(INJURY_MOOD_PENALTY)
			leave()
	return {"bonus_points": BONUS_PER_MINUTE * minutes, "injured_now": injured_now}

func treat(needs: Needs) -> bool:
	if not injured:
		return false
	injured = false
	needs.set_mood_penalty(0.0)
	return true

func speed_multiplier() -> float:
	return 0.5 if injured else 1.0

func is_active() -> bool:
	return active_set != null and not injured
