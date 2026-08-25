extends SceneTree
## Pure Vendor archetype, menu, markup, and affordability tests.

var failures := 0

func _initialize() -> void:
	var archetypes := VendorCatalog.all_archetypes()
	check(archetypes.size() >= 3, "Vendors are built from reusable archetypes")
	var has_affordable_food := false
	var bladder_drink: VendorItem
	for archetype in archetypes:
		check(not archetype.menu.is_empty(), "%s has a named menu" % archetype.display_name)
		for item in archetype.menu:
			check(not item.display_name.is_empty() and item.base_price > 0.0,
				"every menu item has a name and price")
			check(not item.need_restoration.is_empty() and item.mood_bonus >= 0.0 \
				and item.poisoning_risk >= 0.0, "every item declares restoration, Mood, and poisoning risk")
			if item.is_food and item.base_price <= 6.0:
				has_affordable_food = true
			if not item.is_food and item.need_restoration.has(Needs.Kind.BLADDER):
				bladder_drink = item
	check(has_affordable_food, "at least one food option is affordable from the starting Budget")
	var item := archetypes[0].menu[0]
	var vendor := Vendor.new(null, archetypes[0], 1.25)
	check(vendor.price_for(item) == snappedf(item.base_price * 1.25, 0.01),
		"location markup is applied consistently")
	check(FacilityQueue.duration_for(FestivalPoint.Kind.VENDOR, 1.0) <= FacilityQueue.MAX_QUEUE_MINUTES,
		"Vendor Queues reuse the bounded crowd-scaled duration")
	var needs := Needs.new()
	needs.adjust(Needs.Kind.THIRST, -60.0)
	needs.adjust(Needs.Kind.MOOD, -30.0)
	var bladder_before := needs.get_value(Needs.Kind.BLADDER)
	bladder_drink.apply(needs)
	check(needs.get_value(Needs.Kind.THIRST) > 40.0 and needs.get_value(Needs.Kind.MOOD) > 70.0 \
		and needs.get_value(Needs.Kind.BLADDER) < bladder_before,
		"non-alcoholic drink applies restoration, Mood, and Bladder effects exactly once")
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
