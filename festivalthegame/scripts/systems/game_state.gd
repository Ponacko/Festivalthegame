extends Node
## Holds the state of the current Run (autoload "Game").
##
## Slice 1 scope: the player's Needs, Budget, and Enjoyment Score. Needs decay
## is driven centrally here off the Clock; other systems (walking, eating) apply
## their own adjustments to `needs`.

const STARTING_BUDGET := 120.0

var needs: Needs
var lineup: Lineup
var current_configuration: RunConfiguration
var run_seed := 0
var budget := STARTING_BUDGET
var enjoyment_score := 0.0

func _ready() -> void:
	Clock.time_advanced.connect(_on_time_advanced)
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
	Clock.reset()

func _on_time_advanced(minutes: float) -> void:
	if needs != null:
		needs.decay(minutes)

func _default_configuration() -> RunConfiguration:
	var configuration := RunConfiguration.new()
	configuration.add_favorite("Your Favourite", "f66d7266-eb3d-4ef3-b4d8-b7cd992f918b")
	return configuration

func _new_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi()
