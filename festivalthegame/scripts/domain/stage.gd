class_name Stage
extends RefCounted
## A venue where Sets are performed. `position` is its world location; audience
## zones are concentric bands around it (see Audience).

var id: String
var display_name: String
var position: Vector2

func _init(p_id := "", p_display_name := "", p_position := Vector2.ZERO) -> void:
	id = p_id
	display_name = p_display_name
	position = p_position
