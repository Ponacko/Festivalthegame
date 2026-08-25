class_name FestivalPoint
extends RefCounted
## A named destination shared by the world, navigation, and in-game map.

enum Kind { STAGE, CAMPSITE_AREA, VENDOR, TOILET, WATER, FIRST_AID, LATE_VENDOR }

const ALL_KINDS := [
	Kind.STAGE, Kind.CAMPSITE_AREA, Kind.VENDOR, Kind.TOILET,
	Kind.WATER, Kind.FIRST_AID, Kind.LATE_VENDOR,
]

var id: String
var display_name: String
var kind: Kind
var position: Vector2

func _init(p_id := "", p_name := "", p_kind := Kind.STAGE, p_position := Vector2.ZERO) -> void:
	id = p_id
	display_name = p_name
	kind = p_kind
	position = p_position

static func kind_name(value: Kind) -> String:
	match value:
		Kind.STAGE: return "Stages"
		Kind.CAMPSITE_AREA: return "Campsite areas"
		Kind.VENDOR: return "Vendors"
		Kind.TOILET: return "Toilets"
		Kind.WATER: return "Water taps"
		Kind.FIRST_AID: return "First Aid"
		Kind.LATE_VENDOR: return "Late-night Vendors"
	return "Destination"
