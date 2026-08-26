class_name MeetResponse
extends RefCounted
## Explainable result of a deterministic Group Chat meet request.

var accepted: bool
var message: String

func _init(p_accepted := false, p_message := "") -> void:
	accepted = p_accepted
	message = p_message
