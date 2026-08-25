extends SceneTree
## Public domain tests for seeded Festival placement and navigation.

var failures := 0

func _initialize() -> void:
	var config := RunConfiguration.new()
	config.add_favorite("Favorite", "cc28f5aa-5e19-487c-88e1-e56b022f1fdd")
	var lineup := FestivalGenerator.generate(
		config, 707, GenreCatalog.load_bundled(), GenreGraph.load_bundled())
	var first := FestivalGroundsGenerator.generate(lineup, 707)
	var repeated := FestivalGroundsGenerator.generate(lineup, 707)
	var different := FestivalGroundsGenerator.generate(lineup, 708)

	check(first.placement_signature() == repeated.placement_signature(), "same Run seed reproduces destination placement")
	check(first.placement_signature() != different.placement_signature(), "another Run seed changes generated placement")
	var required := [
		FestivalPoint.Kind.STAGE,
		FestivalPoint.Kind.CAMPSITE_AREA,
		FestivalPoint.Kind.VENDOR,
		FestivalPoint.Kind.TOILET,
		FestivalPoint.Kind.WATER,
		FestivalPoint.Kind.FIRST_AID,
		FestivalPoint.Kind.LATE_VENDOR,
	]
	for kind in required:
		check(not first.points_of_kind(kind).is_empty(), "%s destinations are present" % FestivalPoint.kind_name(kind))
	check(first.points_of_kind(FestivalPoint.Kind.STAGE).size() == 4, "all generated Stages are placed on the grounds")

	var separated := true
	for left_index in range(first.points.size()):
		var point := first.points[left_index]
		separated = separated and first.is_walkable(point.position)
		for right_index in range(left_index + 1, first.points.size()):
			separated = separated and point.position.distance_to(first.points[right_index].position) >= 48.0
	check(separated, "destinations are walkable and meaningfully separated")

	var all_reachable := true
	for point in first.points:
		var route := first.path(Vector2.ZERO, point.position)
		all_reachable = all_reachable and not route.is_empty()
		for waypoint in route:
			all_reachable = all_reachable and first.is_walkable(waypoint, 12.0)
	check(all_reachable, "every destination has a walkable route from the entrance")
	var outside_route := first.path(Vector2.ZERO, Vector2(99999, 99999))
	check(not outside_route.is_empty() and first.bounds.has_point(outside_route[-1]),
		"navigation clamps taps to the walkable Festival bounds")

	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
