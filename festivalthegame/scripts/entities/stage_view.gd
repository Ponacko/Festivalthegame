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
	var active_set: FestivalSet = Game.lineup.active_set_for(_stage, Clock.total_minutes) if Game.lineup else null
	if active_set != null:
		var popularity := active_set.artist.popularity
		draw_circle(Vector2.ZERO, Audience.BACK_RADIUS, Color(1, 1, 1, 0.025 + popularity * 0.035))
		draw_circle(Vector2.ZERO, Audience.MID_RADIUS, Color(1, 1, 1, 0.035 + popularity * 0.055))
		draw_circle(Vector2.ZERO, Audience.FRONT_RADIUS, Color(1, 1, 1, 0.05 + popularity * 0.09))
		if MoshPit.is_available(active_set, _stage.position, Clock.total_minutes, Game.mosh_genres):
			draw_circle(Vector2.ZERO, Audience.FRONT_RADIUS * 0.55, Color(0.95, 0.25, 0.35, 0.28))
	else:
		draw_arc(Vector2.ZERO, Audience.BACK_RADIUS, 0.0, TAU, 64, Color(1, 1, 1, 0.12), 2.0)
	# Pixel PA towers, deck, lights, and deterministic popularity-sized crowd.
	draw_rect(Rect2(-64, -42, 128, 84), PixelArt.INK)
	draw_rect(Rect2(-56, -34, 112, 66), Color("774fa3"))
	draw_rect(Rect2(-48, 24, 96, 8), Color("f6c85f"))
	for x in [-48, -16, 16, 48]:
		draw_rect(Rect2(x - 4, -28, 8, 8), Color("77e6ff" if active_set != null else "65708c"))
	if active_set != null:
		var crowd_count := 8 + int(active_set.artist.popularity * 24.0)
		for index in range(crowd_count):
			var column := index % 8
			var row := index / 8
			var crowd_position := Vector2(-70 + column * 20, 68 + row * 21)
			draw_rect(Rect2(crowd_position - Vector2(4, 4), Vector2(8, 8)),
				PixelArt.FRIENDS[index % PixelArt.FRIENDS.size()])
