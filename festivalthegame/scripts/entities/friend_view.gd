class_name FriendView
extends Node2D
## Autonomous world avatar following a Friend's generated itinerary.

const SPEED := 105.0

var friend: FestivalFriend
var grounds: FestivalGrounds
var _destination := Vector2.ZERO
var _route: Array[Vector2] = []

func setup(value: FestivalFriend, festival_grounds: FestivalGrounds) -> void:
	friend = value
	grounds = festival_grounds
	position = value.camp_position

func _ready() -> void:
	add_to_group("friends")
	var label := Label.new()
	label.text = friend.display_name
	label.position = Vector2(-25, 14)
	add_child(label)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if Clock.paused or Game.is_action_locked():
		return
	var wanted := friend.destination_position_at(Clock.total_minutes, grounds)
	if wanted != _destination:
		_destination = wanted
		_route = grounds.path(global_position, wanted)
	if _route.is_empty():
		return
	var next := _route[0]
	var step := SPEED * Clock.time_scale * delta
	global_position = global_position.move_toward(next, step)
	if global_position.distance_to(next) <= 2.0:
		_route.pop_front()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 10.0, Color("f3b5d2"))
