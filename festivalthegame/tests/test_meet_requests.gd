extends SceneTree
## Deterministic acceptance, decline, travel timing, and replanning.

var failures := 0

func _initialize() -> void:
	var grounds := FestivalGrounds.new()
	grounds.points = [
		FestivalPoint.new("camp", "Camp", FestivalPoint.Kind.CAMP, Vector2.ZERO),
		FestivalPoint.new("near", "Near Water", FestivalPoint.Kind.WATER, Vector2(100, 0)),
		FestivalPoint.new("far", "Far Stage", FestivalPoint.Kind.STAGE, Vector2(950, 550)),
	]
	var stage := Stage.new("stage", "Stage", Vector2(600, 0))
	var artist := Artist.new("Artist", "genre")
	var current := FestivalSet.new(artist, stage, 0.0, 60.0)
	var next := FestivalSet.new(artist, stage, 200.0, 260.0)
	var friend := FestivalFriend.new()
	friend.id = "friend_1"
	friend.display_name = "Alex"
	friend.index = 0
	friend.camp_position = Vector2.ZERO
	friend.schedule = [current, next]
	var original_schedule := friend.schedule_signature()

	var committed := MeetRequest.evaluate(friend, grounds.points[1], 20.0, stage.position, grounds)
	check(not committed.accepted and committed.message.contains("watching"),
		"Friend declines during a current Set commitment")
	check(friend.schedule_signature() == original_schedule, "decline leaves personal schedule unchanged")
	var accepted := MeetRequest.evaluate(friend, grounds.points[1], 100.0, Vector2.ZERO, grounds)
	check(accepted.accepted and accepted.message.contains("meet"), "reachable request with schedule room is accepted")
	check(friend.meet_destination == grounds.points[1] \
		and friend.destination_position_at(110.0, grounds) == grounds.points[1].position,
		"acceptance replans the Friend toward the selected destination")

	friend.clear_meet_request()
	friend.schedule = [FestivalSet.new(artist, stage, 115.0, 180.0)]
	var unreachable := MeetRequest.evaluate(friend, grounds.points[2], 100.0, Vector2.ZERO, grounds)
	check(not unreachable.accepted and unreachable.message.contains("time"),
		"Friend declines when travel cannot fit before the next Set")
	var repeated := MeetRequest.preview(friend, grounds.points[2], 100.0, Vector2.ZERO, grounds)
	check(repeated.accepted == unreachable.accepted and repeated.message == unreachable.message,
		"identical meet inputs produce a deterministic response")
	check(not MeetRequest.evaluate(friend, FestivalPoint.new("fake", "Fake"), 100.0, Vector2.ZERO, grounds).accepted,
		"requests reject destinations that are not on the generated map")
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
