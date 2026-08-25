extends Node2D
## Root of the playable scene. Spawns a StageView per Stage in the current
## Lineup and handles dev hotkeys; gameplay lives in the autoloads and child nodes.

@onready var _setup: RunSetupView = $SetupLayer/RunSetup
@onready var _hud: CanvasLayer = $Hud
@onready var _schedule: ScheduleView = $PlannerLayer/Schedule
@onready var _festival_map: FestivalMapView = $MapLayer/FestivalMap
@onready var _player: Node2D = $Player
var _stage_views: Array[StageView] = []
var _planner_was_paused := false
var _map_was_paused := false

func _ready() -> void:
	_setup.configuration_submitted.connect(_on_configuration_submitted)
	_hud.schedule_requested.connect(_open_schedule)
	_hud.pause_requested.connect(_toggle_pause)
	_hud.speed_requested.connect(_cycle_speed)
	_hud.map_requested.connect(_open_map)
	_schedule.closed.connect(_on_schedule_closed)
	_festival_map.closed.connect(_on_map_closed)
	_open_setup()
	_spawn_stage_views()
	_spawn_ground_features()

func _spawn_stage_views() -> void:
	for view in _stage_views:
		view.queue_free()
	_stage_views.clear()
	if Game.lineup == null:
		return
	for stage in Game.lineup.stages:
		var view := StageView.new()
		view.setup(stage)
		add_child(view)
		_stage_views.append(view)

func _spawn_ground_features() -> void:
	for child in $GroundFeatures.get_children():
		child.queue_free()
	if Game.grounds == null:
		return
	for point in Game.grounds.points:
		if point.kind == FestivalPoint.Kind.STAGE:
			continue
		var view := GroundFeatureView.new()
		view.setup(point)
		$GroundFeatures.add_child(view)
	for obstacle in Game.grounds.obstacles:
		var body := StaticBody2D.new()
		body.position = obstacle.get_center()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = obstacle.size
		collision.shape = shape
		body.add_child(collision)
		$GroundFeatures.add_child(body)

func _open_setup() -> void:
	Clock.paused = true
	_schedule.hide()
	_festival_map.hide()
	_setup.reset()
	_setup.show()

func _on_configuration_submitted(configuration: RunConfiguration) -> void:
	Game.start_new_run(configuration)
	_spawn_stage_views()
	_spawn_ground_features()
	_setup.hide()
	Clock.paused = false

func _open_schedule() -> void:
	if Game.lineup == null or _setup.visible:
		return
	_planner_was_paused = Clock.paused
	Clock.paused = true
	_schedule.show_schedule(Game.lineup, FestivalTime.day(Clock.total_minutes))

func _on_schedule_closed() -> void:
	Clock.paused = _planner_was_paused

func _open_map() -> void:
	if Game.grounds == null or _setup.visible or _schedule.visible:
		return
	_map_was_paused = Clock.paused
	Clock.paused = true
	_festival_map.show_map(Game.grounds, _player)

func _on_map_closed() -> void:
	Clock.paused = _map_was_paused

func _toggle_pause() -> void:
	if not _setup.visible and not _schedule.visible and not _festival_map.visible:
		Clock.toggle_paused()

func _cycle_speed() -> void:
	if not _setup.visible and not _schedule.visible and not _festival_map.visible:
		Clock.cycle_time_scale()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_toggle_pause()
			KEY_R:
				_open_setup()
			KEY_BRACKETRIGHT:
				Clock.cycle_time_scale(1)
			KEY_BRACKETLEFT:
				Clock.cycle_time_scale(-1)
