class_name AlcoholItem
extends VendorItem
## Cartoonish alcoholic drink with explicit potency and duration.

var potency: float
var duration_minutes: float

func _init(
		p_id: String,
		p_name: String,
		p_price: float,
		p_mood: float,
		p_social: float,
		p_bladder: float,
		p_potency: float,
		p_duration: float) -> void:
	super(p_id, p_name, p_price, {
		Needs.Kind.SOCIAL: p_social,
		Needs.Kind.BLADDER: p_bladder,
	}, p_mood, 0.0, false)
	potency = p_potency
	duration_minutes = p_duration

func effect_summary() -> String:
	return "%s, Tipsy +%.0f%% for %.0f min" % [super(), potency * 100.0, duration_minutes]
