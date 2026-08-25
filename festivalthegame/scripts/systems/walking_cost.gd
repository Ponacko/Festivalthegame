class_name WalkingCost
extends RefCounted
## Need costs derived only from distance the avatar actually covered.

const ENERGY_PER_PIXEL := 0.02
const THIRST_PER_PIXEL := 0.01

static func apply(needs: Needs, actual_distance: float) -> void:
	if needs == null or actual_distance <= 0.0:
		return
	needs.adjust(Needs.Kind.ENERGY, -ENERGY_PER_PIXEL * actual_distance)
	needs.adjust(Needs.Kind.THIRST, -THIRST_PER_PIXEL * actual_distance)
