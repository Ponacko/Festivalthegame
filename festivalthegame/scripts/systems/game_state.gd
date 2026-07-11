extends Node
## Holds the state of the current Run (autoload "Game").
##
## Slice 1 scope: the player's Needs, Budget, and Enjoyment Score. Needs decay
## is driven centrally here off the Clock; other systems (walking, eating) apply
## their own adjustments to `needs`.

const STARTING_BUDGET := 120.0

var needs: Needs
var lineup: Lineup
var budget := STARTING_BUDGET
var enjoyment_score := 0.0

func _ready() -> void:
	Clock.time_advanced.connect(_on_time_advanced)
	start_new_run()

func start_new_run() -> void:
	needs = Needs.new()
	lineup = Lineup.build_demo()
	budget = STARTING_BUDGET
	enjoyment_score = 0.0
	Clock.reset()

func _on_time_advanced(minutes: float) -> void:
	if needs != null:
		needs.decay(minutes)
