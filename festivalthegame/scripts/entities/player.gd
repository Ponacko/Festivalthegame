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
	add_to_group("player")
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	# Touch is delivered as a mouse event via emulate_mouse_from_touch.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		move_to(get_global_mouse_position())

func move_to(world_position: Vector2) -> void:
	if Game.is_action_locked() or (Game.facility_queue != null and Game.facility_queue.is_active()):
		return
	_route = Game.grounds.path(global_position, world_position) if Game.grounds != null else [world_position]
	if not _route.is_empty():
		_target = _route.pop_front()
		_moving = true

func _physics_process(_delta: float) -> void:
	if Clock.paused or Game.is_action_locked() \
			or (Game.facility_queue != null and Game.facility_queue.is_active()):
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
	var direction := Game.tipsy.movement_direction(to_target, Clock.total_minutes)
	velocity = direction * SPEED * Clock.time_scale * crowd_speed * Game.mosh.speed_multiplier()
	var before := global_position
	move_and_slide()
	var walked := global_position.distance_to(before)
	WalkingCost.apply(Game.needs, walked)

func relocate_to(world_position: Vector2) -> void:
	_route.clear()
	_moving = false
	velocity = Vector2.ZERO
	global_position = world_position

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_ellipse_shadow()
	var effect := Color.TRANSPARENT
	if Game.mosh != null and Game.mosh.injured:
		effect = Color("ff4e5b")
	elif Game.food_poisoning != null and Game.food_poisoning.is_active():
		effect = Color("78d64b")
	elif Game.tipsy != null and Game.tipsy.is_active():
		effect = Color("ffd166")
	PixelArt.person(self, PixelArt.PLAYER, effect)

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0, 17), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 12.0, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO)
