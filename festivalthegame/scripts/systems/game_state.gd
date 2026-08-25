extends Node
## Holds the state of the current Run (autoload "Game").
##
## Slice 1 scope: the player's Needs, Budget, and Enjoyment Score. Needs decay
## is driven centrally here off the Clock; other systems (walking, eating) apply
## their own adjustments to `needs`.

const STARTING_BUDGET := 120.0

signal night_choices_requested(day: int)
signal morning_recap_requested(completed_day: int)
signal autosave_requested(reason: String)
signal final_scoring_requested
signal run_completed
signal facility_queue_started(facility_name: String, duration: float)
signal facility_queue_finished(message: String)
signal facility_queue_interrupted(message: String)
signal vendor_purchase_rejected(message: String)

enum RunStatus { NOT_STARTED, PLAYING, COMPLETE }

var needs: Needs
var lineup: Lineup
var grounds: FestivalGrounds
var current_configuration: RunConfiguration
var run_seed := 0
var budget := STARTING_BUDGET
var score_ledger := ScoreLedger.new()
var facility_queue := FacilityQueue.new()
var run_status := RunStatus.NOT_STARTED
var _festival_maximum := 0.0
var _pending_vendor: Vendor
var _pending_vendor_item: VendorItem

func _ready() -> void:
	Clock.time_advanced.connect(_on_time_advanced)
	Clock.night_started.connect(_on_night_started)
	Clock.morning_started.connect(_on_morning_started)
	Clock.run_completed.connect(_on_run_completed)
	Clock.reset()

func start_new_run(configuration: RunConfiguration = null, seed_value := -1) -> void:
	if configuration != null:
		current_configuration = configuration
	elif current_configuration == null:
		current_configuration = _default_configuration()
	run_seed = seed_value if seed_value >= 0 else _new_seed()
	current_configuration.lock()
	needs = Needs.new()
	lineup = FestivalGenerator.generate(
		current_configuration,
		run_seed,
		GenreCatalog.load_bundled(),
		GenreGraph.load_bundled())
	grounds = FestivalGroundsGenerator.generate(lineup, run_seed, current_configuration)
	budget = STARTING_BUDGET
	score_ledger = ScoreLedger.new()
	facility_queue = FacilityQueue.new()
	_pending_vendor = null
	_pending_vendor_item = null
	_festival_maximum = TheoreticalMaximum.calculate(lineup)
	run_status = RunStatus.PLAYING
	Clock.reset()

func record_attendance(
		festival_set: FestivalSet,
		minutes: float,
		affinity_multiplier: float,
		zone_multiplier: float,
		needs_multiplier: float) -> ScoreEntry:
	return score_ledger.record_attendance(
		festival_set, minutes, affinity_multiplier, zone_multiplier, needs_multiplier)

func award_bonus(source_name: String, points: float) -> float:
	var entry := score_ledger.record_bonus(source_name, points)
	return entry.points if entry != null else 0.0

func current_score() -> float:
	return score_ledger.total()

func theoretical_maximum() -> float:
	# Named bonuses may introduce points outside the attendance model. Keeping the
	# reported ceiling at least as high preserves a meaningful bounded percentage.
	return maxf(_festival_maximum, current_score())

func score_percentage() -> float:
	var maximum := theoretical_maximum()
	return 0.0 if maximum <= 0.0 else current_score() / maximum * 100.0

func _on_time_advanced(minutes: float) -> void:
	if needs != null:
		needs.decay(minutes)
	if facility_queue.is_active():
		var message := facility_queue.advance(minutes, needs)
		if not message.is_empty():
			if _pending_vendor != null and _pending_vendor_item != null:
				var price := _pending_vendor.price_for(_pending_vendor_item)
				budget -= price
				_pending_vendor_item.apply(needs)
				message = "%s purchased for €%.2f." % [_pending_vendor_item.display_name, price]
				_pending_vendor = null
				_pending_vendor_item = null
			facility_queue_finished.emit(message)

func queue_preview(facility: FestivalPoint) -> float:
	if facility == null:
		return 0.0
	var density := CrowdField.density(lineup, facility.position, Clock.total_minutes)
	return FacilityQueue.duration_for(facility.kind, density)

func start_facility_queue(facility: FestivalPoint, player_position: Vector2) -> bool:
	if facility == null or player_position.distance_to(facility.position) > 90.0:
		return false
	var density := CrowdField.density(lineup, facility.position, Clock.total_minutes)
	if not facility_queue.start(facility, density):
		return false
	facility_queue_started.emit(facility.display_name, facility_queue.total_minutes)
	return true

func interrupt_facility_queue() -> bool:
	var message := facility_queue.interrupt()
	if message.is_empty():
		return false
	_pending_vendor = null
	_pending_vendor_item = null
	facility_queue_interrupted.emit(message)
	return true

func vendor_queue_preview(vendor: Vendor) -> float:
	return queue_preview(vendor.point) if vendor != null else 0.0

func start_vendor_purchase(vendor: Vendor, item: VendorItem, player_position: Vector2) -> bool:
	if vendor == null or item == null or not vendor.archetype.menu.has(item):
		return false
	var price := vendor.price_for(item)
	if budget < price:
		vendor_purchase_rejected.emit("Not enough Budget for %s (€%.2f)." % [item.display_name, price])
		return false
	if not start_facility_queue(vendor.point, player_position):
		return false
	_pending_vendor = vendor
	_pending_vendor_item = item
	return true

func nearest_facility(world_position: Vector2, maximum_distance := 90.0) -> FestivalPoint:
	if grounds == null:
		return null
	var closest: FestivalPoint = null
	var closest_distance := maximum_distance
	for kind in [FestivalPoint.Kind.WATER, FestivalPoint.Kind.TOILET, FestivalPoint.Kind.VENDOR]:
		for point in grounds.points_of_kind(kind):
			var distance := world_position.distance_to(point.position)
			if distance <= closest_distance:
				closest = point
				closest_distance = distance
	return closest

func _on_night_started(day: int) -> void:
	if day < FestivalTime.PLAYABLE_DAYS:
		night_choices_requested.emit(day)
		autosave_requested.emit("night_started")

func _on_morning_started(day: int) -> void:
	morning_recap_requested.emit(day - 1)
	autosave_requested.emit("morning_started")

func _on_run_completed() -> void:
	run_status = RunStatus.COMPLETE
	final_scoring_requested.emit()
	autosave_requested.emit("run_completed")
	run_completed.emit()

func _default_configuration() -> RunConfiguration:
	var configuration := RunConfiguration.new()
	configuration.add_favorite("Your Favourite", "f66d7266-eb3d-4ef3-b4d8-b7cd992f918b")
	configuration.select_campsite("camp_1")
	return configuration

func _new_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi()
