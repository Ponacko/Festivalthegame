extends Node
## Holds the state of the current Run (autoload "Game").
##
## Slice 1 scope: the player's Needs, Budget, and Enjoyment Score. Needs decay
## is driven centrally here off the Clock; other systems (walking, eating) apply
## their own adjustments to `needs`.

const STARTING_BUDGET := 120.0

signal night_choices_requested(day: int)
signal morning_recap_requested(completed_day: int)
signal autosave_requested(reason: String)
signal final_scoring_requested
signal run_completed

enum RunStatus { NOT_STARTED, PLAYING, COMPLETE }

var needs: Needs
var lineup: Lineup
var current_configuration: RunConfiguration
var run_seed := 0
var budget := STARTING_BUDGET
var enjoyment_score := 0.0
var run_status := RunStatus.NOT_STARTED

func _ready() -> void:
	Clock.time_advanced.connect(_on_time_advanced)
	Clock.night_started.connect(_on_night_started)
	Clock.morning_started.connect(_on_morning_started)
	Clock.run_completed.connect(_on_run_completed)
	Clock.reset()

func start_new_run(configuration: RunConfiguration = null, seed_value := -1) -> void:
	if configuration != null:
		current_configuration = configuration
	elif current_configuration == null:
		current_configuration = _default_configuration()
	run_seed = seed_value if seed_value >= 0 else _new_seed()
	needs = Needs.new()
	lineup = FestivalGenerator.generate(
		current_configuration,
		run_seed,
		GenreCatalog.load_bundled(),
		GenreGraph.load_bundled())
	budget = STARTING_BUDGET
	enjoyment_score = 0.0
	run_status = RunStatus.PLAYING
	Clock.reset()

func _on_time_advanced(minutes: float) -> void:
	if needs != null:
		needs.decay(minutes)

func _on_night_started(day: int) -> void:
	if day < FestivalTime.PLAYABLE_DAYS:
		night_choices_requested.emit(day)
		autosave_requested.emit("night_started")

func _on_morning_started(day: int) -> void:
	morning_recap_requested.emit(day - 1)
	autosave_requested.emit("morning_started")

func _on_run_completed() -> void:
	run_status = RunStatus.COMPLETE
	final_scoring_requested.emit()
	autosave_requested.emit("run_completed")
	run_completed.emit()

func _default_configuration() -> RunConfiguration:
	var configuration := RunConfiguration.new()
	configuration.add_favorite("Your Favourite", "f66d7266-eb3d-4ef3-b4d8-b7cd992f918b")
	return configuration

func _new_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi()
