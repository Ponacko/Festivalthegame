class_name GroundFeatureView
extends Node2D
## Lightweight world marker for a generated Festival destination.

var point: FestivalPoint

func setup(value: FestivalPoint) -> void:
	point = value
	position = value.position

func _ready() -> void:
	var label := Label.new()
	label.text = point.display_name
	label.position = Vector2(-48, 16)
	label.custom_minimum_size = Vector2(96, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 12.0, _color_for(point.kind))

func _color_for(kind: FestivalPoint.Kind) -> Color:
	match kind:
		FestivalPoint.Kind.CAMPSITE_AREA: return Color("77a866")
		FestivalPoint.Kind.VENDOR, FestivalPoint.Kind.LATE_VENDOR: return Color("e6a15c")
		FestivalPoint.Kind.TOILET: return Color("b68ce0")
		FestivalPoint.Kind.WATER: return Color("55bde8")
		FestivalPoint.Kind.FIRST_AID: return Color("ef6464")
	return Color.WHITE
