extends SceneTree
## Deterministic group sizes, tastes, schedules, camp, and destinations.

var failures := 0

func _initialize() -> void:
	var catalog := GenreCatalog.load_bundled()
	var graph := GenreGraph.load_bundled()
	for friend_count in range(5):
		var config := RunConfiguration.new()
		config.add_favorite("Metal Favorite", "cc28f5aa-5e19-487c-88e1-e56b022f1fdd")
		config.set_friend_count(friend_count)
		config.select_campsite("camp_2")
		var lineup := FestivalGenerator.generate(config, 1717, catalog, graph)
		var grounds := FestivalGroundsGenerator.generate(lineup, 1717, config)
		var friends := FriendGenerator.generate(config, lineup, grounds, graph, 1717)
		check(friends.size() == friend_count, "configured group size %d creates exactly %d Friends" % [friend_count, friend_count])
		for friend in friends:
			check(friend.camp_position == grounds.camp.position, "%s shares the selected campsite" % friend.display_name)

	var config := RunConfiguration.new()
	config.add_favorite("Metal Favorite", "cc28f5aa-5e19-487c-88e1-e56b022f1fdd")
	config.set_friend_count(4)
	config.select_campsite("camp_1")
	var lineup := FestivalGenerator.generate(config, 1720, catalog, graph)
	var grounds := FestivalGroundsGenerator.generate(lineup, 1720, config)
	var first := FriendGenerator.generate(config, lineup, grounds, graph, 1720)
	var repeated := FriendGenerator.generate(config, lineup, grounds, graph, 1720)
	check(FestivalFriend.group_signature(first) == FestivalFriend.group_signature(repeated),
		"Friend tastes and personal schedules are deterministic from the Run seed")
	var schedules := {}
	for friend in first:
		schedules[friend.schedule_signature()] = true
		check(friend.average_scheduled_affinity(graph) >= 0.45,
			"%s's chosen Sets reflect their generated tastes" % friend.display_name)
		var visits_facility := false
		for minute in range(0, FestivalTime.MINUTES_PER_DAY, 30):
			if friend.destination_kind_at(float(minute), grounds) in [FestivalPoint.Kind.WATER, FestivalPoint.Kind.TOILET]:
				visits_facility = true
				break
		check(visits_facility, "%s autonomously plans relevant facility stops" % friend.display_name)
	check(schedules.size() > 1, "Friends follow independent schedules rather than one copied route")
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
