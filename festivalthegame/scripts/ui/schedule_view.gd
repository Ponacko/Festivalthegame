class_name ScheduleView
extends Control
## Touch-first Lineup planner grouped by Festival Day.

signal closed

@onready var _title: Label = $Panel/Margin/Content/Title
@onready var _set_list: VBoxContainer = $Panel/Margin/Content/Sets/SetList

var _lineup: Lineup
var _catalog: GenreCatalog
var _conflicted := {}
var _day := 1
var _row_labels: Array[Label] = []

func _ready() -> void:
	_catalog = GenreCatalog.load_bundled()
	$Panel/Margin/Content/Days/Day1.pressed.connect(func() -> void: _show_day(1))
	$Panel/Margin/Content/Days/Day2.pressed.connect(func() -> void: _show_day(2))
	$Panel/Margin/Content/Days/Day3.pressed.connect(func() -> void: _show_day(3))
	$Panel/Margin/Content/Close.pressed.connect(_on_close)

func show_schedule(lineup: Lineup, festival_day: int) -> void:
	_lineup = lineup
	_conflicted = SchedulePlanner.conflicted_sets(lineup)
	show()
	_show_day(clampi(festival_day, 1, FestivalGenerator.DAY_COUNT))

func displayed_day() -> int:
	return _day

func displayed_set_count() -> int:
	return _row_labels.size()

func rendered_text() -> String:
	var lines := PackedStringArray()
	for label in _row_labels:
		lines.append(label.text)
	return "\n".join(lines)

func _show_day(festival_day: int) -> void:
	_day = festival_day
	_title.text = "Festival Day %d Schedule" % festival_day
	for child in _set_list.get_children():
		child.queue_free()
	_row_labels.clear()
	if _lineup == null:
		return
	for festival_set in SchedulePlanner.sets_for_day(_lineup, festival_day):
		var genre := _catalog.find_by_id(festival_set.artist.genre_id)
		var favorite := " ★" if festival_set.artist.is_favorite else ""
		var warning := "  ⚠ CONFLICT" if _conflicted.has(festival_set) else ""
		var row := Label.new()
		row.custom_minimum_size = Vector2(0, 38)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.text = "%s–%s  |  %s  |  %s%s  |  %s%s" % [
			FestivalTime.clock_string(festival_set.start_minute),
			FestivalTime.clock_string(festival_set.end_minute),
			festival_set.stage.display_name,
			festival_set.artist.name,
			favorite,
			genre.display_name if genre else festival_set.artist.genre_id,
			warning,
		]
		_set_list.add_child(row)
		_row_labels.append(row)

func _on_close() -> void:
	hide()
	closed.emit()

