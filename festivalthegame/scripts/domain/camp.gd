class_name Camp
extends RefCounted
## The selected shared home base for the player and configured Friends.

var profile: CampsiteProfile
var position: Vector2
var interaction_position: Vector2
var friend_count: int
var can_change_clothes := true

func _init(p_profile: CampsiteProfile, p_position: Vector2, p_friend_count: int) -> void:
	profile = p_profile
	position = p_position
	interaction_position = p_position
	friend_count = p_friend_count

func resident_count() -> int:
	return friend_count + 1
