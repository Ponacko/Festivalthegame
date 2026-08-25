class_name CampsiteProfile
extends RefCounted
## Visible, immutable trade-offs for one campsite area.

var id: String
var display_name: String
var walking_distance: float
var sleep_quality: float
var noise: float
var nightlife: float

func _init(p_id: String, p_name: String, p_walk: float, p_sleep: float, p_noise: float, p_nightlife: float) -> void:
	id = p_id
	display_name = p_name
	walking_distance = p_walk
	sleep_quality = p_sleep
	noise = p_noise
	nightlife = p_nightlife

func tradeoff_summary() -> String:
	return "Walk: %s  •  Sleep: %s  •  Noise: %s  •  Nightlife: %s" % [
		_level(walking_distance, true),
		_level(sleep_quality),
		_level(noise),
		_level(nightlife),
	]

func _level(value: float, inverse := false) -> String:
	var labels := ["Low", "Medium", "High"]
	var index := clampi(int(floor(value * 3.0)), 0, 2)
	if inverse:
		labels = ["Short", "Medium", "Long"]
	return labels[index]
