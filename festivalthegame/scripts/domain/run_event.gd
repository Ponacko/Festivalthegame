class_name RunEvent
extends RefCounted
## Durable recap/war-story fact recorded during a Run.

var event_type: String
var total_minutes: float
var detail: String

func _init(p_type: String, p_time: float, p_detail: String) -> void:
	event_type = p_type
	total_minutes = p_time
	detail = p_detail
