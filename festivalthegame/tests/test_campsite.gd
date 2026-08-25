extends SceneTree
## Public domain tests for campsite trade-offs and Run choice validation.

var failures := 0

func _initialize() -> void:
	var profiles := CampsiteCatalog.all_profiles()
	check(profiles.size() == 3, "three campsite trade-offs are offered")
	var summaries := {}
	for profile in profiles:
		summaries[profile.tradeoff_summary()] = true
		check(profile.walking_distance > 0.0 and profile.sleep_quality > 0.0,
			"%s exposes walking and sleep properties" % profile.display_name)
		check(profile.tradeoff_summary().contains("Noise") and profile.tradeoff_summary().contains("Nightlife"),
			"%s communicates noise and nightlife" % profile.display_name)
	check(summaries.size() == profiles.size(), "candidate campsites have distinct trade-offs")

	var config := RunConfiguration.new()
	config.add_favorite("Favorite", "genre-id")
	check(not config.is_valid(), "a campsite must be chosen before the Festival")
	check(not config.select_campsite("not-a-camp"), "unknown campsite choices are rejected")
	check(config.select_campsite(profiles[1].id) and config.is_valid(), "one known campsite completes Run setup")
	config.lock()
	config.select_campsite(profiles[0].id)
	check(config.campsite_id == profiles[1].id, "the campsite choice is permanent once the Run starts")

	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
