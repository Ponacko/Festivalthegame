extends Node
## Shared-experience scoring and solo Social balancing through Game APIs.

var failures := 0

func _ready() -> void:
	var config := RunConfiguration.new()
	config.add_favorite("Metal Favorite", "cc28f5aa-5e19-487c-88e1-e56b022f1fdd")
	config.set_friend_count(2)
	config.select_campsite("camp_1")
	Game.start_new_run(config, 1721)
	check(Game.friends.size() == 2, "Run state contains exactly the configured Friends")
	Game.needs.adjust(Needs.Kind.SOCIAL, -50.0)
	Game.needs.adjust(Needs.Kind.MOOD, -50.0)
	var social_before := Game.needs.get_value(Needs.Kind.SOCIAL)
	var mood_before := Game.needs.get_value(Needs.Kind.MOOD)
	var shared_set: FestivalSet = Game.lineup.sets[0]
	Game.apply_friend_presence(5.0, 2, 1, shared_set)
	check(Game.needs.get_value(Needs.Kind.SOCIAL) > social_before \
		and Game.needs.get_value(Needs.Kind.MOOD) > mood_before,
		"nearby Friends restore Social and Mood over time")
	check(Game.current_score() > 0.0 and Game.score_ledger.entries[-1].source_name.contains("Shared experience"),
		"same-Set proximity adds a named shared-experience ledger bonus")
	var score_with_friend := Game.current_score()
	Game.apply_friend_presence(5.0, 0, 0, shared_set)
	check(Game.current_score() == score_with_friend, "bonus stops promptly when proximity ends")

	var solo := RunConfiguration.new()
	solo.add_favorite("Solo Favorite", "cc28f5aa-5e19-487c-88e1-e56b022f1fdd")
	solo.set_friend_count(0)
	solo.select_campsite("camp_1")
	Game.start_new_run(solo, 1722)
	var solo_social := Game.needs.get_value(Needs.Kind.SOCIAL)
	Clock.advance_game_minutes(60.0)
	var passive_loss := solo_social - Game.needs.get_value(Needs.Kind.SOCIAL)
	check(passive_loss < 6.0, "zero-Friend Runs drain Social more slowly")
	Game.apply_solo_crowd_atmosphere(60.0)
	check(Game.needs.get_value(Needs.Kind.SOCIAL) >= solo_social - 1.0,
		"crowd atmosphere keeps solo Social viable")

	if failures == 0:
		print("ALL FRIEND FLOW TESTS PASSED")
	else:
		printerr("%d FRIEND FLOW TEST(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
