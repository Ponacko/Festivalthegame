class_name MeetRequest
extends RefCounted
## Deterministic policy for the phone's single "meet me at X" command.

const FRIEND_SPEED := 105.0
const MEET_DURATION := 30.0
const MINIMUM_MEET_MINUTES := 10.0
const SET_BUFFER := 5.0

static func preview(
		friend: FestivalFriend,
		destination: FestivalPoint,
		total_minutes: float,
		current_position: Vector2,
		grounds: FestivalGrounds) -> MeetResponse:
	return _decide(friend, destination, total_minutes, current_position, grounds, false)

static func evaluate(
		friend: FestivalFriend,
		destination: FestivalPoint,
		total_minutes: float,
		current_position: Vector2,
		grounds: FestivalGrounds) -> MeetResponse:
	return _decide(friend, destination, total_minutes, current_position, grounds, true)

static func _decide(
		friend: FestivalFriend,
		destination: FestivalPoint,
		total_minutes: float,
		current_position: Vector2,
		grounds: FestivalGrounds,
		commit: bool) -> MeetResponse:
	if friend == null or destination == null or grounds == null or not grounds.points.has(destination):
		return MeetResponse.new(false, "I can't meet there — that isn't a map destination.")
	var active := friend.current_set(total_minutes)
	if active != null:
		return MeetResponse.new(false, "Can't right now — I'm watching %s." % active.artist.name)
	var route := grounds.path(current_position, destination.position)
	if route.is_empty():
		return MeetResponse.new(false, "I can't reach %s from here." % destination.display_name)
	var travel_minutes := _route_length(current_position, route) / FRIEND_SPEED
	var next_set := friend.next_set_after(total_minutes)
	if next_set != null:
		var onward_route := grounds.path(destination.position, next_set.stage.position)
		if onward_route.is_empty():
			return MeetResponse.new(false, "I can't reach my next Set from there.")
		var onward_minutes := _route_length(destination.position, onward_route) / FRIEND_SPEED
		var required := travel_minutes + MINIMUM_MEET_MINUTES + onward_minutes + SET_BUFFER
		if total_minutes + required > next_set.start_minute:
			return MeetResponse.new(false, "Not enough time before %s — I'll stick to my plan." % next_set.artist.name)
	var meet_until := total_minutes + travel_minutes + MEET_DURATION
	if next_set != null:
		var onward := _route_length(destination.position, grounds.path(destination.position, next_set.stage.position)) / FRIEND_SPEED
		meet_until = minf(meet_until, next_set.start_minute - SET_BUFFER - onward)
	if commit:
		friend.meet_destination = destination
		friend.meet_until = meet_until
	return MeetResponse.new(true, "Yes — I'll meet you at %s." % destination.display_name)

static func _route_length(start: Vector2, route: Array[Vector2]) -> float:
	var length := 0.0
	var previous := start
	for point in route:
		length += previous.distance_to(point)
		previous = point
	return length
