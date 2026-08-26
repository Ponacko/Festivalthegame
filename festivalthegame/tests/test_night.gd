extends Node
## Night calculations and irreversible phase boundaries.

var failures := 0

func _ready() -> void:
	var quiet := CampsiteProfile.new("quiet", "Quiet", 0.5, 0.9, 0.1, 0.3)
	var loud := CampsiteProfile.new("loud", "Loud", 0.5, 0.9, 0.9, 0.9)
	check(NightState.energy_recovery_per_hour(quiet, 0.0) > NightState.energy_recovery_per_hour(loud, 0.0),
		"noise reduces campsite sleep recovery")
	check(NightState.energy_recovery_per_hour(quiet, 0.8) < NightState.energy_recovery_per_hour(quiet, 0.0),
		"Tipsy level reduces sleep recovery")
	var needs := Needs.new()
	needs.adjust(Needs.Kind.SOCIAL, -70.0)
	needs.adjust(Needs.Kind.MOOD, -70.0)
	var hunger_before := needs.get_value(Needs.Kind.HUNGER)
	NightState.apply_party(60.0, needs, loud)
	check(needs.get_value(Needs.Kind.SOCIAL) > 30.0 and needs.get_value(Needs.Kind.MOOD) > 30.0,
		"campsite partying raises Social and Mood")
	check(needs.get_value(Needs.Kind.HUNGER) < hunger_before, "passive Needs continue draining while partying")
	var energy_before := needs.get_value(Needs.Kind.ENERGY)
	NightState.apply_sleep(120.0, needs, quiet, 0.0)
	check(needs.get_value(Needs.Kind.ENERGY) > energy_before, "sleep recovers Energy from campsite quality")

	var config := RunConfiguration.new()
	config.add_favorite("Favorite", "cc28f5aa-5e19-487c-88e1-e56b022f1fdd")
	config.select_campsite("camp_1")
	Game.start_new_run(config, 1919)
	Clock.advance_game_minutes(FestivalTime.arena_close_minute(1))
	check(Game.night.active and Game.night.day == 1, "arena close begins exactly one night choice phase")
	var start := Clock.total_minutes
	check(Game.party_for_hour(), "player can remain at the campsite party")
	check(Clock.total_minutes == start + 60.0 and Game.night.party_minutes == 60.0,
		"party time is spent and cannot be recovered")
	check(not Game.late_night_vendors().is_empty(), "late food is exposed only through mapped late Vendors")
	var late_vendor := Game.late_night_vendors()[0]
	var late_item := late_vendor.archetype.menu[0]
	var budget_before := Game.budget
	var roll_before := Game.poisoning_roll_count
	check(Game.complete_late_vendor_purchase(late_vendor, late_item), "late food uses the normal Vendor purchase path")
	check(Game.budget < budget_before and Game.poisoning_roll_count == roll_before + 1,
		"late food uses normal Budget, Queue completion, item, and poisoning rules")
	check(Game.sleep_until_morning(), "player can switch from partying to sleep")
	check(Clock.total_minutes == FestivalTime.festival_day_start(2) and not Game.night.active,
		"sleep reaches the next Festival Day boundary exactly once")
	check(Game.run_events.any(func(event: RunEvent) -> bool: return event.event_type == "night_summary"),
		"night choices and outcomes are durable recap events")
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
