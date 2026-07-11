class_name Needs
extends RefCounted
## The player's six decaying Needs.
##
## Convention: every value is a *satisfaction* in [0, MAX] where MAX is good
## and 0 triggers a penalty. Bladder at MAX means comfortable/empty; drinking
## lowers it toward an accident. The combined state produces the multiplier
## applied to Enjoyment earned per minute (see enjoyment_multiplier).

enum Kind { HUNGER, THIRST, ENERGY, BLADDER, SOCIAL, MOOD }

const MAX := 100.0
const ALL := [Kind.HUNGER, Kind.THIRST, Kind.ENERGY, Kind.BLADDER, Kind.SOCIAL, Kind.MOOD]

const NAMES := {
	Kind.HUNGER: "Hunger",
	Kind.THIRST: "Thirst",
	Kind.ENERGY: "Energy",
	Kind.BLADDER: "Bladder",
	Kind.SOCIAL: "Social",
	Kind.MOOD: "Mood",
}

# Passive satisfaction lost per game-minute. Tuning values: the denominator is
# roughly how many game-hours the need takes to drain from full while idle.
# Action-driven needs (Bladder) barely drift on their own.
const PASSIVE_DECAY := {
	Kind.HUNGER: 100.0 / (8.0 * 60.0),
	Kind.THIRST: 100.0 / (5.0 * 60.0),
	Kind.ENERGY: 100.0 / (16.0 * 60.0),
	Kind.BLADDER: 100.0 / (40.0 * 60.0),
	Kind.SOCIAL: 100.0 / (10.0 * 60.0),
	Kind.MOOD: 100.0 / (12.0 * 60.0),
}

# Bounds of the enjoyment multiplier driven by overall needs state.
const MULT_MIN := 0.25
const MULT_MAX := 1.25

var _values := {}

func _init() -> void:
	for k in ALL:
		_values[k] = MAX

func get_value(kind: int) -> float:
	return _values[kind]

func fraction(kind: int) -> float:
	return _values[kind] / MAX

func adjust(kind: int, delta: float) -> void:
	_values[kind] = clampf(_values[kind] + delta, 0.0, MAX)

func decay(game_minutes: float) -> void:
	for k in ALL:
		adjust(k, -PASSIVE_DECAY[k] * game_minutes)

func is_empty(kind: int) -> bool:
	return _values[kind] <= 0.0

## Multiplier applied to Enjoyment earned per minute. Uses mean satisfaction
## across all needs, but any single fully-empty need floors it to MULT_MIN —
## being wrecked in one dimension ruins the whole experience.
func enjoyment_multiplier() -> float:
	for k in ALL:
		if is_empty(k):
			return MULT_MIN
	var sum := 0.0
	for k in ALL:
		sum += fraction(k)
	var avg := sum / ALL.size()
	return MULT_MIN + avg * (MULT_MAX - MULT_MIN)
