extends Node
## Purchase completion, rejection, cancellation, and item effects through Game.

var failures := 0

func _ready() -> void:
	Game.start_new_run(null, 1111)
	Clock.set_paused(false)
	var vendor: Vendor = Game.grounds.vendors[0]
	var item: VendorItem = vendor.archetype.menu[0]
	Game.needs.adjust(Needs.Kind.HUNGER, -80.0)
	var hunger_before := Game.needs.get_value(Needs.Kind.HUNGER)
	var score_before := Game.current_score()
	Game.budget = 0.0
	check(not Game.start_vendor_purchase(vendor, item, vendor.point.position),
		"purchase is rejected when Budget is insufficient")
	check(not Game.facility_queue.is_active() and Game.needs.get_value(Needs.Kind.HUNGER) == hunger_before,
		"rejected purchase has no Queue or Need side effects")

	Game.budget = Game.STARTING_BUDGET
	var expected_price := vendor.price_for(item)
	var wait := Game.vendor_queue_preview(vendor)
	check(Game.start_vendor_purchase(vendor, item, vendor.point.position), "affordable purchase joins the Vendor Queue")
	check(Game.budget == Game.STARTING_BUDGET, "Budget is not charged before service completes")
	Clock.advance(wait)
	check(absf(Game.budget - (Game.STARTING_BUDGET - expected_price)) < 0.001,
		"successful purchase applies marked-up price exactly once")
	check(Game.needs.get_value(Needs.Kind.HUNGER) > hunger_before, "purchased food applies its restoration")
	check(Game.current_score() == score_before, "purchases never reduce Enjoyment Score")
	var after_purchase_budget := Game.budget
	var after_purchase_hunger := Game.needs.get_value(Needs.Kind.HUNGER)
	Clock.advance(1.0)
	check(Game.budget == after_purchase_budget, "completed purchase is never charged twice")

	check(Game.start_vendor_purchase(vendor, item, vendor.point.position), "another purchase can enter its Queue")
	Clock.advance(Game.facility_queue.remaining_minutes * 0.5)
	Game.interrupt_facility_queue()
	check(Game.budget == after_purchase_budget, "cancelled Vendor Queue does not charge Budget")
	check(Game.needs.get_value(Needs.Kind.HUNGER) <= after_purchase_hunger,
		"cancelled Vendor Queue applies no item restoration")

	if failures == 0:
		print("ALL VENDOR FLOW TESTS PASSED")
	else:
		printerr("%d VENDOR FLOW TEST(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
