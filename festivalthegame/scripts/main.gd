extends Node2D
## Root of the playable scene. Spawns a StageView per Stage in the current
## Lineup and handles dev hotkeys; gameplay lives in the autoloads and child nodes.

func _ready() -> void:
	for stage in Game.lineup.stages:
		var view := StageView.new()
		view.setup(stage)
		add_child(view)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				Clock.paused = not Clock.paused
			KEY_R:
				Game.start_new_run()
			KEY_BRACKETRIGHT:
				Clock.time_scale = minf(Clock.time_scale * 2.0, 64.0)
			KEY_BRACKETLEFT:
				Clock.time_scale = maxf(Clock.time_scale / 2.0, 0.25)
