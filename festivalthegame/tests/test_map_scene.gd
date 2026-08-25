extends Node
## User-visible map flow at a tall mobile aspect ratio.

var failures := 0
var closed := false

func _ready() -> void:
	get_tree().root.size = Vector2i(720, 1280)
	Game.start_new_run(null, 717)
	var player := Node2D.new()
	player.position = Vector2(123, -45)
	add_child(player)
	var original_position := player.position
	var map: FestivalMapView = load("res://scenes/festival_map.tscn").instantiate()
	add_child(map)
	map.closed.connect(func() -> void: closed = true)
	map.show_map(Game.grounds, player)

	check(map.visible, "map opens at a supported mobile aspect ratio")
	check(map.marker_count() == Game.grounds.points.size() + 1, "map has one marker for every world destination and the player")
	for kind in FestivalPoint.ALL_KINDS:
		check(map.has_marker_kind(kind), "map identifies %s" % FestivalPoint.kind_name(kind))
	check(map.has_player_marker(), "map identifies the player")
	check(player.position == original_position, "opening and inspecting the map never teleports the player")
	var close_button := map.get_node("Panel/Margin/Content/Close") as Button
	check(close_button.custom_minimum_size.y >= 48.0, "map close action is touch-sized")
	close_button.pressed.emit()
	check(closed and not map.visible, "map closes back to the same world position")

	if failures == 0:
		print("ALL MAP SCENE TESTS PASSED")
	else:
		printerr("%d MAP SCENE TEST(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
