class_name Audience
extends RefCounted
## Audience zones around a Stage. Closer = more Enjoyment (and, later, denser
## crowd and higher movement cost). Distance is measured from the Stage center.

enum Zone { NONE, BACK, MID, FRONT }

const FRONT_RADIUS := 120.0
const MID_RADIUS := 240.0
const BACK_RADIUS := 400.0

const MULTIPLIER := {
	Zone.NONE: 0.0,
	Zone.BACK: 1.0,
	Zone.MID: 1.15,
	Zone.FRONT: 1.3,
}

const ZONE_NAME := {
	Zone.NONE: "—",
	Zone.BACK: "Back",
	Zone.MID: "Mid",
	Zone.FRONT: "Front",
}

static func zone_at(distance: float) -> int:
	if distance <= FRONT_RADIUS:
		return Zone.FRONT
	if distance <= MID_RADIUS:
		return Zone.MID
	if distance <= BACK_RADIUS:
		return Zone.BACK
	return Zone.NONE

static func multiplier(zone: int) -> float:
	return MULTIPLIER[zone]

static func zone_name(zone: int) -> String:
	return ZONE_NAME[zone]
