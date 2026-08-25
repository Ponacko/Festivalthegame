class_name FoodPoisoning
extends RefCounted
## Delayed, deterministic, timed illness caused by a risky purchase.

enum State { NONE, PENDING, ACTIVE }

const ONSET_DELAY_MINUTES := 45.0
const ACTIVE_MINUTES := 3.0 * 60.0
const THIRST_DRAIN_PER_MINUTE := 0.35
const BLADDER_DRAIN_PER_MINUTE := 0.80
const MOOD_CEILING := 15.0
const URGENT_INTERVAL_MINUTES := 30.0

var state := State.NONE
var pending_minutes := 0.0
var active_minutes := 0.0
var urgent_minutes := 0.0

static func roll(risk: float, rng: RandomNumberGenerator) -> bool:
	return rng.randf() < clampf(risk, 0.0, 1.0)

func schedule() -> bool:
	if state != State.NONE:
		return false
	state = State.PENDING
	pending_minutes = ONSET_DELAY_MINUTES
	return true

func advance(minutes: float, needs: Needs) -> PackedStringArray:
	var events := PackedStringArray()
	var remaining := maxf(0.0, minutes)
	if state == State.PENDING and remaining > 0.0:
		var pending_step := minf(remaining, pending_minutes)
		pending_minutes -= pending_step
		remaining -= pending_step
		if pending_minutes <= 0.0001:
			pending_minutes = 0.0
			state = State.ACTIVE
			active_minutes = ACTIVE_MINUTES
			urgent_minutes = URGENT_INTERVAL_MINUTES
			events.append("onset")
	if state == State.ACTIVE and remaining > 0.0:
		var active_step := minf(remaining, active_minutes)
		needs.adjust(Needs.Kind.THIRST, -THIRST_DRAIN_PER_MINUTE * active_step)
		needs.adjust(Needs.Kind.BLADDER, -BLADDER_DRAIN_PER_MINUTE * active_step)
		enforce_mood(needs)
		active_minutes -= active_step
		urgent_minutes -= active_step
		while urgent_minutes <= 0.0001 and active_minutes > 0.0001:
			events.append("urgent")
			urgent_minutes += URGENT_INTERVAL_MINUTES
		if active_minutes <= 0.0001:
			state = State.NONE
			active_minutes = 0.0
			events.append("recovered")
	return events

func enforce_mood(needs: Needs) -> void:
	if state == State.ACTIVE and needs.get_value(Needs.Kind.MOOD) > MOOD_CEILING:
		needs.adjust(Needs.Kind.MOOD, MOOD_CEILING - needs.get_value(Needs.Kind.MOOD))

func is_pending() -> bool:
	return state == State.PENDING

func is_active() -> bool:
	return state == State.ACTIVE
