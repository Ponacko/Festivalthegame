class_name Stage
extends RefCounted
## A venue where Sets are performed. `position` is its world location; audience
## zones are concentric bands around it (see Audience).

enum Size { SMALL, MID, MAIN }

var id: String
var display_name: String
var position: Vector2
var size: Size

func _init(p_id := "", p_display_name := "", p_position := Vector2.ZERO, p_size := Size.MID) -> void:
	id = p_id
	display_name = p_display_name
	position = p_position
	size = p_size

func accepts_popularity(popularity: float) -> bool:
	match size:
		Size.MAIN:
			return popularity >= 0.75
		Size.MID:
			return popularity >= 0.35 and popularity < 0.85
		Size.SMALL:
			return popularity < 0.50
	return false
