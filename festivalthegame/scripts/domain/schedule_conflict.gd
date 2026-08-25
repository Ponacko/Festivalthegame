class_name ScheduleConflict
extends RefCounted
## Two desirable Sets whose overlap forces a planning choice.

var first: FestivalSet
var second: FestivalSet

func _init(p_first: FestivalSet, p_second: FestivalSet) -> void:
	first = p_first
	second = p_second

