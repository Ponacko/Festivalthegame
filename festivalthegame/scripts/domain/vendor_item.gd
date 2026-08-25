class_name VendorItem
extends RefCounted
## One food or non-alcoholic drink with explicit trade-offs.

var id: String
var display_name: String
var base_price: float
var need_restoration: Dictionary
var mood_bonus: float
var poisoning_risk: float
var is_food: bool

func _init(
		p_id: String,
		p_name: String,
		p_price: float,
		p_restoration: Dictionary,
		p_mood: float,
		p_risk: float,
		p_is_food: bool) -> void:
	id = p_id
	display_name = p_name
	base_price = p_price
	need_restoration = p_restoration
	mood_bonus = p_mood
	poisoning_risk = clampf(p_risk, 0.0, 1.0)
	is_food = p_is_food

func apply(needs: Needs) -> void:
	for kind in need_restoration:
		needs.adjust(kind, float(need_restoration[kind]))
	needs.adjust(Needs.Kind.MOOD, mood_bonus)

func effect_summary() -> String:
	var parts := PackedStringArray()
	for kind in need_restoration:
		parts.append("%s %+.0f" % [Needs.NAMES[kind], float(need_restoration[kind])])
	parts.append("Mood %+.0f" % mood_bonus)
	parts.append("risk %.0f%%" % (poisoning_risk * 100.0))
	return ", ".join(parts)
