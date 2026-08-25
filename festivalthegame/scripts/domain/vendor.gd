class_name Vendor
extends RefCounted
## One placed archetype with a visible location markup.

var point: FestivalPoint
var archetype: VendorArchetype
var markup: float

func _init(p_point: FestivalPoint, p_archetype: VendorArchetype, p_markup := 1.0) -> void:
	point = p_point
	archetype = p_archetype
	markup = maxf(1.0, p_markup)

func price_for(item: VendorItem) -> float:
	return snappedf(item.base_price * markup, 0.01)
