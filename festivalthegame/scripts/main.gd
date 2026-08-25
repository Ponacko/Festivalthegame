extends Node2D
## Root of the playable scene. Spawns a StageView per Stage in the current
## Lineup and handles dev hotkeys; gameplay lives in the autoloads and child nodes.

@onready var _setup: RunSetupView = $SetupLayer/RunSetup
var _stage_views: Array[StageView] = []

func _ready() -> void:
	_setup.configuration_submitted.connect(_on_configuration_submitted)
	_open_setup()
	_spawn_stage_views()

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

func _open_setup() -> void:
	Clock.paused = true
	_setup.reset()
	_setup.show()

func _on_configuration_submitted(configuration: RunConfiguration) -> void:
	Game.start_new_run(configuration)
	_spawn_stage_views()
	_setup.hide()
	Clock.paused = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				Clock.paused = not Clock.paused
			KEY_R:
				_open_setup()
			KEY_BRACKETRIGHT:
				Clock.time_scale = minf(Clock.time_scale * 2.0, 64.0)
			KEY_BRACKETLEFT:
				Clock.time_scale = maxf(Clock.time_scale / 2.0, 0.25)
