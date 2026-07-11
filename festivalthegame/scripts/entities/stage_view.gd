class_name StageView
extends Node2D
## Visual for one Stage: a marker box, translucent Audience Zone rings, and a
## label showing the Stage name and its currently playing Set.

var _stage: Stage
var _label: Label

func setup(stage: Stage) -> void:
	_stage = stage
	position = stage.position

func _ready() -> void:
	_label = Label.new()
	_label.position = Vector2(-70, -Audience.BACK_RADIUS - 28)
	_label.custom_minimum_size = Vector2(140, 0)
	add_child(_label)

func _process(_delta: float) -> void:
	queue_redraw()
	var s: FestivalSet = Game.lineup.active_set_for(_stage, Clock.total_minutes) if Game.lineup else null
	if s != null:
		var star := " ★" if s.artist.is_favorite else ""
		_label.text = "%s\n%s%s" % [_stage.display_name, s.artist.name, star]
	else:
		_label.text = "%s\n(no set)" % _stage.display_name

func _draw() -> void:
	draw_circle(Vector2.ZERO, Audience.BACK_RADIUS, Color(1, 1, 1, 0.05))
	draw_circle(Vector2.ZERO, Audience.MID_RADIUS, Color(1, 1, 1, 0.06))
	draw_circle(Vector2.ZERO, Audience.FRONT_RADIUS, Color(1, 1, 1, 0.08))
	draw_rect(Rect2(-60, -40, 120, 80), Color(0.5, 0.3, 0.6, 1))
