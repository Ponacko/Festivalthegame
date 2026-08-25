extends Node
## Alcohol purchase applies Tipsy and amplified Need effects exactly once.

var failures := 0

func _ready() -> void:
	Game.start_new_run(null, 1515)
	Clock.set_paused(false)
	var bar: Vendor
	for vendor in Game.grounds.vendors:
		if vendor.archetype.id == "festival_bar":
			bar = vendor
			break
	check(bar != null, "generated Festival places the alcohol Vendor archetype")
	var drink := bar.archetype.menu[0] as AlcoholItem
	Game.needs.adjust(Needs.Kind.MOOD, -50.0)
	Game.needs.adjust(Needs.Kind.SOCIAL, -50.0)
	var mood_before := Game.needs.get_value(Needs.Kind.MOOD)
	var social_before := Game.needs.get_value(Needs.Kind.SOCIAL)
	Game.start_vendor_purchase(bar, drink, bar.point.position)
	Clock.advance(Game.facility_queue.remaining_minutes)
	check(Game.tipsy.is_active() and Game.tipsy.remaining_minutes > 0.0,
		"drinking exposes bounded Tipsy level and remaining duration")
	check(Game.needs.get_value(Needs.Kind.MOOD) > mood_before \
		and Game.needs.get_value(Needs.Kind.SOCIAL) > social_before,
		"alcohol purchase applies amplified Mood and Social benefits")
	check(Game.poisoning_roll_count == 0, "alcohol is not routed through food poisoning rolls")
	if failures == 0:
		print("ALL TIPSY FLOW TESTS PASSED")
	else:
		printerr("%d TIPSY FLOW TEST(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
