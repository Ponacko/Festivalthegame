extends CharacterBody2D
## Tap-to-move avatar. Moves toward the last tapped/clicked world point.
## Walking is the game's universal cost: it drains extra Energy and Thirst
## in proportion to distance actually covered.

const SPEED := 140.0          # pixels per real-second
const ARRIVE_DISTANCE := 4.0
const ENERGY_PER_PIXEL := 0.02
const THIRST_PER_PIXEL := 0.01

var _target: Vector2
var _moving := false

func _ready() -> void:
	_target = global_position

func _unhandled_input(event: InputEvent) -> void:
	# Touch is delivered as a mouse event via emulate_mouse_from_touch.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_target = get_global_mouse_position()
		_moving = true

func _physics_process(_delta: float) -> void:
	if not _moving:
		return
	var to_target := _target - global_position
	if to_target.length() <= ARRIVE_DISTANCE:
		_moving = false
		velocity = Vector2.ZERO
		return
	velocity = to_target.normalized() * SPEED
	var before := global_position
	move_and_slide()
	var walked := global_position.distance_to(before)
	if walked > 0.0 and Game.needs != null:
		Game.needs.adjust(Needs.Kind.ENERGY, -ENERGY_PER_PIXEL * walked)
		Game.needs.adjust(Needs.Kind.THIRST, -THIRST_PER_PIXEL * walked)
