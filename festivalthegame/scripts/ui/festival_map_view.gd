class_name FestivalMapView
extends Control
## Read-only, touch-first overview of the continuous Festival grounds.

signal closed

@onready var _canvas: Control = $Panel/Margin/Content/MapScroll/MapCanvas
var _grounds: FestivalGrounds
var _player: Node2D
var _markers: Array[Label] = []
var _kinds := {}
var _player_marker: Label

func _ready() -> void:
	$Panel/Margin/Content/Close.pressed.connect(_on_close)

func show_map(grounds: FestivalGrounds, player: Node2D) -> void:
	_grounds = grounds
	_player = player
	_render_markers()
	show()

func marker_count() -> int:
	return _markers.size()

func has_marker_kind(kind: FestivalPoint.Kind) -> bool:
	return _kinds.has(kind)

func has_player_marker() -> bool:
	return _player_marker != null

func _process(_delta: float) -> void:
	if visible and _player_marker != null and _player != null:
		_player_marker.position = _map_position(_player.global_position)

func _render_markers() -> void:
	for marker in _markers:
		marker.queue_free()
	_markers.clear()
	_kinds.clear()
	_player_marker = null
	if _grounds == null:
		return
	for point in _grounds.points:
		var marker := _make_marker(point.display_name, point.position)
		marker.tooltip_text = FestivalPoint.kind_name(point.kind)
		_kinds[point.kind] = true
	_player_marker = _make_marker("YOU", _player.global_position if _player != null else Vector2.ZERO)
	_player_marker.modulate = Color("ffef6f")

func _make_marker(label_text: String, world_position: Vector2) -> Label:
	var marker := Label.new()
	marker.text = "● %s" % label_text
	marker.position = _map_position(world_position)
	marker.add_theme_font_size_override("font_size", 12)
	_canvas.add_child(marker)
	_markers.append(marker)
	return marker

func _map_position(world_position: Vector2) -> Vector2:
	if _grounds == null:
		return Vector2.ZERO
	var normalized := (world_position - _grounds.bounds.position) / _grounds.bounds.size
	return Vector2(normalized.x * 900.0, normalized.y * 430.0)

func _on_close() -> void:
	hide()
	closed.emit()
