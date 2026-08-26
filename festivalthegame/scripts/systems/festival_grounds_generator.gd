class_name FestivalGroundsGenerator
extends RefCounted
## Seeded placement of every v1 destination on a connected site.

static func generate(lineup: Lineup, seed_value: int, configuration: RunConfiguration = null) -> FestivalGrounds:
	var grounds := FestivalGrounds.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x47524f554e4453
	for stage in lineup.stages:
		grounds.points.append(FestivalPoint.new(
			"stage_%s" % stage.id, stage.display_name, FestivalPoint.Kind.STAGE, stage.position))
	_add_group(grounds, rng, FestivalPoint.Kind.CAMPSITE_AREA, "Camp", [
		Vector2(-930, 560), Vector2(-120, 620), Vector2(900, 560)])
	_add_group(grounds, rng, FestivalPoint.Kind.VENDOR, "Vendor", [
		Vector2(-880, -80), Vector2(-300, 80), Vector2(300, -80), Vector2(880, 80)], true)
	_add_group(grounds, rng, FestivalPoint.Kind.TOILET, "Toilets", [
		Vector2(-950, -560), Vector2(0, 560), Vector2(950, -560)], true)
	_add_group(grounds, rng, FestivalPoint.Kind.WATER, "Free Water", [
		Vector2(-430, -610), Vector2(0, 0), Vector2(430, 610)], true)
	_add_group(grounds, rng, FestivalPoint.Kind.FIRST_AID, "First Aid", [Vector2(0, -570)], true)
	_add_group(grounds, rng, FestivalPoint.Kind.LATE_VENDOR, "Late Food", [
		Vector2(-690, 620), Vector2(690, 620)], true)
	_build_vendors(grounds)
	_select_camp(grounds, configuration)
	return grounds

static func _select_camp(grounds: FestivalGrounds, configuration: RunConfiguration) -> void:
	if configuration == null:
		return
	var profile := CampsiteCatalog.find(configuration.campsite_id)
	if profile == null:
		return
	for point in grounds.points:
		if point.id == profile.id:
			point.kind = FestivalPoint.Kind.CAMP
			point.display_name = "Camp — %s" % profile.display_name
			grounds.camp = Camp.new(profile, point.position, configuration.friend_count)
			return

static func _build_vendors(grounds: FestivalGrounds) -> void:
	var archetypes := VendorCatalog.all_archetypes()
	var markups := [1.0, 1.15, 1.25, 1.10]
	var points := grounds.points_of_kind(FestivalPoint.Kind.VENDOR)
	for index in range(points.size()):
		var vendor := Vendor.new(points[index], archetypes[index % archetypes.size()], markups[index % markups.size()])
		vendor.point.display_name = vendor.archetype.display_name
		grounds.vendors.append(vendor)
	var late_archetype := archetypes[2]
	for late_point in grounds.points_of_kind(FestivalPoint.Kind.LATE_VENDOR):
		var late_vendor := Vendor.new(late_point, late_archetype, 1.15)
		late_vendor.point.display_name = "Late-night %s" % late_archetype.display_name
		grounds.vendors.append(late_vendor)

static func _add_group(
		grounds: FestivalGrounds,
		rng: RandomNumberGenerator,
		kind: FestivalPoint.Kind,
		prefix: String,
		base_positions: Array,
		add_obstacle := false) -> void:
	for index in range(base_positions.size()):
		var base: Vector2 = base_positions[index]
		var position := base + Vector2(rng.randf_range(-20.0, 20.0), rng.randf_range(-20.0, 20.0))
		grounds.points.append(FestivalPoint.new(
			"%s_%d" % [prefix.to_snake_case(), index + 1],
			"%s %d" % [prefix, index + 1],
			kind,
			position))
		if add_obstacle:
			grounds.obstacles.append(Rect2(position + Vector2(-28, -76), Vector2(56, 38)))
