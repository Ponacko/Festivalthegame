extends Node
## Phone UI lists plans and exposes the single touch command without time cost.

var failures := 0
var requested := false

func _ready() -> void:
	var config := RunConfiguration.new()
	config.add_favorite("Favorite", "cc28f5aa-5e19-487c-88e1-e56b022f1fdd")
	config.set_friend_count(2)
	config.select_campsite("camp_1")
	Game.start_new_run(config, 1818)
	var chat: GroupChatView = load("res://scenes/group_chat.tscn").instantiate()
	add_child(chat)
	chat.meet_requested.connect(func(_friend: FestivalFriend, _destination: FestivalPoint) -> void: requested = true)
	var time_before := Clock.total_minutes
	chat.show_chat(Game.friends, Game.grounds)
	var text := chat.rendered_text()
	for friend in Game.friends:
		check(text.contains(friend.display_name), "Group Chat lists %s" % friend.display_name)
	check(text.contains("Location:") and text.contains("Activity:") and text.contains("Next:"),
		"Group Chat shows location, activity, and next planned Set")
	check(chat.destination_count() == Game.grounds.points.size(), "meet destination list mirrors valid map destinations")
	var send := chat.get_node("Panel/Margin/Content/Send") as Button
	check(send.text.to_lower().contains("meet me at") and send.custom_minimum_size.y >= 48.0,
		"the only touch command is meet me at X")
	send.pressed.emit()
	check(requested, "touch command submits the selected Friend and destination")
	check(Clock.total_minutes == time_before, "opening and using Group Chat never advances time automatically")
	if failures == 0:
		print("ALL GROUP CHAT TESTS PASSED")
	else:
		printerr("%d GROUP CHAT TEST(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
