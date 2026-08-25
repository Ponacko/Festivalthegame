extends SceneTree
## Pure Queue scaling and bounds.

var failures := 0

func _initialize() -> void:
	var empty_water := FacilityQueue.duration_for(FestivalPoint.Kind.WATER, 0.0)
	var crowded_water := FacilityQueue.duration_for(FestivalPoint.Kind.WATER, 1.0)
	var empty_toilet := FacilityQueue.duration_for(FestivalPoint.Kind.TOILET, 0.0)
	check(crowded_water > empty_water, "Queue duration scales predictably with nearby crowd density")
	check(empty_toilet > empty_water, "toilets take longer than free water taps")
	check(FacilityQueue.duration_for(FestivalPoint.Kind.TOILET, 100.0) <= FacilityQueue.MAX_QUEUE_MINUTES,
		"Queue duration has a finite upper bound")
	check(FacilityQueue.duration_for(FestivalPoint.Kind.STAGE, 1.0) == 0.0,
		"non-facility destinations cannot create Queues")
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
