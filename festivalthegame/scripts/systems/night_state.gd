class_name NightState
extends RefCounted
## Mutable state for one explicit overnight choice phase.

const BASE_ENERGY_PER_HOUR := 24.0
const PARTY_SOCIAL_PER_HOUR := 16.0
const PARTY_MOOD_PER_HOUR := 12.0

var active := false
var day := 0
var party_minutes := 0.0
var sleep_minutes := 0.0
var transition_applied := false

func begin(festival_day: int) -> void:
	active = true
	day = festival_day
	party_minutes = 0.0
	sleep_minutes = 0.0
	transition_applied = false

func finish() -> void:
	active = false
	transition_applied = true

static func energy_recovery_per_hour(profile: CampsiteProfile, tipsy_level: float) -> float:
	var quality := 0.5 + profile.sleep_quality
	var quietness := 1.0 - profile.noise * 0.55
	var sobriety := 1.0 - clampf(tipsy_level, 0.0, 1.0) * 0.45
	return BASE_ENERGY_PER_HOUR * quality * quietness * sobriety

static func apply_party(minutes: float, needs: Needs, profile: CampsiteProfile) -> void:
	needs.decay(minutes)
	var hours := minutes / 60.0
	needs.adjust(Needs.Kind.SOCIAL, PARTY_SOCIAL_PER_HOUR * (0.5 + profile.nightlife) * hours)
	needs.adjust(Needs.Kind.MOOD, PARTY_MOOD_PER_HOUR * (0.5 + profile.nightlife) * hours)

static func apply_sleep(minutes: float, needs: Needs, profile: CampsiteProfile, tipsy_level: float) -> void:
	needs.decay(minutes)
	needs.adjust(Needs.Kind.ENERGY, energy_recovery_per_hour(profile, tipsy_level) * minutes / 60.0)
