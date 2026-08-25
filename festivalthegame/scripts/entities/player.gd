extends CharacterBody2D
## Tap-to-move avatar. Moves toward the last tapped/clicked world point.
## Walking is the game's universal cost: it drains extra Energy and Thirst
## in proportion to distance actually covered.

const SPEED := 140.0          # pixels per real-second
const ARRIVE_DISTANCE := 4.0

var _target: Vector2
var _moving := false
var _route: Array[Vector2] = []

func _ready() -> void:
	_target = global_position

func _unhandled_input(event: InputEvent) -> void:
	# Touch is delivered as a mouse event via emulate_mouse_from_touch.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		move_to(get_global_mouse_position())

func move_to(world_position: Vector2) -> void:
	_route = Game.grounds.path(global_position, world_position) if Game.grounds != null else [world_position]
	if not _route.is_empty():
		_target = _route.pop_front()
		_moving = true

func _physics_process(_delta: float) -> void:
	if Clock.paused:
		velocity = Vector2.ZERO
		return
	if not _moving:
		return
	var to_target := _target - global_position
	if to_target.length() <= ARRIVE_DISTANCE:
		if _route.is_empty():
			_moving = false
			velocity = Vector2.ZERO
		else:
			_target = _route.pop_front()
		return
	var crowd_speed := CrowdField.speed_multiplier(Game.lineup, global_position, Clock.total_minutes)
	velocity = to_target.normalized() * SPEED * Clock.time_scale * crowd_speed
	var before := global_position
	move_and_slide()
	var walked := global_position.distance_to(before)
	WalkingCost.apply(Game.needs, walked)
