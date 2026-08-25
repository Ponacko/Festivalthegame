class_name CampsiteCatalog
extends RefCounted
## The three v1 campsite archetypes offered before a Run.

static func all_profiles() -> Array[CampsiteProfile]:
	return [
		CampsiteProfile.new("camp_1", "Gate Camp", 0.20, 0.70, 0.35, 0.35),
		CampsiteProfile.new("camp_2", "Quiet Meadow", 0.55, 1.00, 0.10, 0.15),
		CampsiteProfile.new("camp_3", "Party Ridge", 0.90, 0.50, 0.95, 1.00),
	]

static func find(profile_id: String) -> CampsiteProfile:
	for profile in all_profiles():
		if profile.id == profile_id:
			return profile
	return null
