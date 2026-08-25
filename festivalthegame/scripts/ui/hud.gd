extends CanvasLayer
## Debug HUD (slice 1): shows the festival clock, Run stats, and a bar per Need.
## Built in code to avoid hand-authoring a deep scene tree.

signal schedule_requested
signal pause_requested
signal speed_requested
signal map_requested
signal vendor_requested(vendor: Vendor)

var _info: Label
var _enjoy: Label
var _bars := {}
var _enjoy_node: Node
var _pause_button: Button
var _speed_button: Button
var _facility_button: Button
var _facility_status: Label
var _nearby_facility: FestivalPoint

func _ready() -> void:
	var schedule_button := Button.new()
	schedule_button.name = "ScheduleButton"
	schedule_button.text = "Schedule"
	schedule_button.custom_minimum_size = Vector2(160, 52)
	schedule_button.anchor_left = 1.0
	schedule_button.anchor_right = 1.0
	schedule_button.offset_left = -172.0
	schedule_button.offset_top = 12.0
	schedule_button.offset_right = -12.0
	schedule_button.offset_bottom = 64.0
	schedule_button.pressed.connect(func() -> void: schedule_requested.emit())
	add_child(schedule_button)

	_pause_button = Button.new()
	_pause_button.name = "PauseButton"
	_pause_button.custom_minimum_size = Vector2(160, 52)
	_pause_button.anchor_left = 1.0
	_pause_button.anchor_right = 1.0
	_pause_button.offset_left = -172.0
	_pause_button.offset_top = 76.0
	_pause_button.offset_right = -12.0
	_pause_button.offset_bottom = 128.0
	_pause_button.pressed.connect(func() -> void: pause_requested.emit())
	add_child(_pause_button)

	_speed_button = Button.new()
	_speed_button.name = "SpeedButton"
	_speed_button.custom_minimum_size = Vector2(160, 52)
	_speed_button.anchor_left = 1.0
	_speed_button.anchor_right = 1.0
	_speed_button.offset_left = -172.0
	_speed_button.offset_top = 140.0
	_speed_button.offset_right = -12.0
	_speed_button.offset_bottom = 192.0
	_speed_button.pressed.connect(func() -> void: speed_requested.emit())
	add_child(_speed_button)

	var map_button := Button.new()
	map_button.name = "MapButton"
	map_button.text = "Map"
	map_button.custom_minimum_size = Vector2(160, 52)
	map_button.anchor_left = 1.0
	map_button.anchor_right = 1.0
	map_button.offset_left = -172.0
	map_button.offset_top = 204.0
	map_button.offset_right = -12.0
	map_button.offset_bottom = 256.0
	map_button.pressed.connect(func() -> void: map_requested.emit())
	add_child(map_button)

	_facility_button = Button.new()
	_facility_button.name = "FacilityButton"
	_facility_button.custom_minimum_size = Vector2(300, 56)
	_facility_button.anchor_top = 1.0
	_facility_button.anchor_bottom = 1.0
	_facility_button.offset_left = 12.0
	_facility_button.offset_top = -68.0
	_facility_button.offset_right = 312.0
	_facility_button.offset_bottom = -12.0
	_facility_button.visible = false
	_facility_button.pressed.connect(_on_facility_pressed)
	add_child(_facility_button)

	_facility_status = Label.new()
	_facility_status.name = "FacilityStatus"
	_facility_status.anchor_top = 1.0
	_facility_status.anchor_bottom = 1.0
	_facility_status.offset_left = 12.0
	_facility_status.offset_top = -100.0
	_facility_status.offset_right = 520.0
	_facility_status.offset_bottom = -72.0
	add_child(_facility_status)
	Game.facility_queue_started.connect(func(facility_name: String, duration: float) -> void:
		_facility_status.text = "Queueing at %s — %.1f min" % [facility_name, duration])
	Game.facility_queue_finished.connect(func(message: String) -> void: _facility_status.text = message)
	Game.facility_queue_interrupted.connect(func(message: String) -> void: _facility_status.text = message)
	Game.collapse_started.connect(func(kind: int) -> void:
		_facility_status.text = "Blackout — %s reached zero…" % Needs.NAMES[kind])
	Game.collapse_completed.connect(func(message: String) -> void: _facility_status.text = message)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	_info = Label.new()
	vbox.add_child(_info)

	_enjoy = Label.new()
	vbox.add_child(_enjoy)

	for k in Needs.ALL:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = Needs.NAMES[k]
		label.custom_minimum_size = Vector2(80, 0)
		row.add_child(label)
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = Needs.MAX
		bar.custom_minimum_size = Vector2(220, 18)
		bar.show_percentage = false
		row.add_child(bar)
		vbox.add_child(row)
		_bars[k] = bar

func _process(_delta: float) -> void:
	_pause_button.text = "Resume" if Clock.paused else "Pause"
	_speed_button.text = "Speed  x%.0f" % Clock.time_scale
	_update_facility_action()
	if Game.needs == null:
		return
	_info.text = "Day %d  %s   %s  x%.2f   Score %.0f   €%.0f   Mult x%.2f\n[tap: move]  [space: pause]  [ [ / ] : speed ]  [R: new run]" % [
		FestivalTime.day(Clock.total_minutes),
		FestivalTime.clock_string(Clock.total_minutes),
		("PAUSED" if Clock.paused else "playing"),
		Clock.time_scale,
		Game.current_score(),
		Game.budget,
		Game.needs.enjoyment_multiplier(),
	]
	for k in Needs.ALL:
		_bars[k].value = Game.needs.get_value(k)

	if _enjoy_node == null:
		_enjoy_node = get_tree().get_first_node_in_group("enjoyment")
	if _enjoy_node != null:
		var stage_name: String = _enjoy_node.current_stage.display_name if _enjoy_node.current_stage != null else "—"
		_enjoy.text = "At: %s  [%s]   +%.2f / min" % [
			stage_name,
			Audience.zone_name(_enjoy_node.current_zone),
			_enjoy_node.current_rate,
		]

func _update_facility_action() -> void:
	if Game.facility_queue != null and Game.facility_queue.is_active():
		_facility_button.visible = true
		_facility_button.text = "Leave Queue  (%.1f min left)" % Game.facility_queue.remaining_minutes
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	_nearby_facility = Game.nearest_facility(player.global_position) if player != null else null
	_facility_button.visible = _nearby_facility != null
	if _nearby_facility != null:
		if _nearby_facility.kind == FestivalPoint.Kind.VENDOR:
			_facility_button.text = "Shop at %s" % _nearby_facility.display_name
		else:
			_facility_button.text = "Use %s  •  Queue %.1f min" % [
				_nearby_facility.display_name, Game.queue_preview(_nearby_facility)]

func _on_facility_pressed() -> void:
	if Game.facility_queue.is_active():
		Game.interrupt_facility_queue()
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if _nearby_facility != null and player != null:
		if _nearby_facility.kind == FestivalPoint.Kind.VENDOR:
			vendor_requested.emit(Game.grounds.vendor_for_point(_nearby_facility))
		else:
			Game.start_facility_queue(_nearby_facility, player.global_position)
