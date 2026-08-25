extends SceneTree
## Pure alcohol variety and deterministic Tipsy behavior.

var failures := 0

func _initialize() -> void:
	var alcohol: Array[AlcoholItem] = []
	for archetype in VendorCatalog.all_archetypes():
		for item in archetype.menu:
			if item is AlcoholItem:
				alcohol.append(item)
	check(alcohol.size() >= 3, "Vendor menus contain multiple alcohol varieties")
	var signatures := {}
	for item in alcohol:
		signatures["%.2f:%.2f:%.1f:%.1f" % [item.base_price, item.potency, item.duration_minutes,
			float(item.need_restoration.get(Needs.Kind.BLADDER, 0.0))]] = true
		check(item.mood_bonus > 0.0 and item.need_restoration.has(Needs.Kind.SOCIAL),
			"%s declares Mood, Social, and Bladder trade-offs" % item.display_name)
	check(signatures.size() == alcohol.size(), "alcohol varieties have distinct price, potency, duration, and Bladder effects")

	var tipsy := TipsyState.new()
	tipsy.consume(alcohol[0])
	var first_duration := tipsy.remaining_minutes
	tipsy.consume(alcohol[1])
	check(tipsy.level > alcohol[0].potency and tipsy.level <= TipsyState.MAX_LEVEL,
		"Tipsy doses stack up to a bounded level")
	check(tipsy.remaining_minutes > first_duration and tipsy.remaining_minutes <= TipsyState.MAX_DURATION_MINUTES,
		"stacking extends duration by the explicit bounded rule")
	check(tipsy.gain_multiplier() > 1.0, "Tipsy boosts positive Mood and Social gains")
	var needs := Needs.new()
	var bladder_before := needs.get_value(Needs.Kind.BLADDER)
	tipsy.advance(20.0, needs)
	check(needs.get_value(Needs.Kind.BLADDER) < bladder_before, "Tipsy accelerates Bladder drain")
	var base_direction := Vector2.RIGHT
	var wobble := tipsy.movement_direction(base_direction, 12.5)
	check(absf(wobble.length() - 1.0) < 0.001 and wobble != base_direction,
		"Tipsy adds readable wobble without stopping movement")
	check(absf(base_direction.angle_to(wobble)) <= TipsyState.MAX_WOBBLE_RADIANS,
		"wobble remains bounded so destinations stay reachable")

	for item in alcohol:
		tipsy.consume(item)
	check(tipsy.level == TipsyState.MAX_LEVEL, "overindulgence cannot exceed maximum Tipsy")
	check(tipsy.next_day_energy_penalty > 0.0, "overindulgence records a next-day Energy penalty")
	var penalty := tipsy.consume_next_day_energy_penalty()
	check(penalty > 0.0 and tipsy.next_day_energy_penalty == 0.0,
		"next-day penalty is applied at most once by sleep recovery")
	tipsy.advance(TipsyState.MAX_DURATION_MINUTES, needs)
	check(not tipsy.is_active() and tipsy.level == 0.0, "Tipsy effects expire deterministically")

	var forbidden := ["cocaine", "heroin", "cannabis", "ecstasy", "amphetamine"]
	for archetype in VendorCatalog.all_archetypes():
		for item in archetype.menu:
			var copy := (item.id + " " + item.display_name).to_lower()
			check(forbidden.all(func(term: String) -> bool: return not copy.contains(term)),
				"Vendor catalog contains no drug-themed items")
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
