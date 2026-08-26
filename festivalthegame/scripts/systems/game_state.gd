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
signal collapse_started(primary_need: int)
signal collapse_completed(message: String)
signal player_relocation_requested(world_position: Vector2)
signal bladder_accident_occurred(message: String)
signal clothes_changed(message: String)
signal food_poisoning_status(message: String)
signal mosh_status(message: String)

enum RunStatus { NOT_STARTED, PLAYING, COMPLETE }

const COLLAPSE_MINUTES := 90.0
const COLLAPSE_RESTORE := 35.0
const COLLAPSE_MOOD := 20.0
const COLLAPSE_NEEDS := [Needs.Kind.HUNGER, Needs.Kind.THIRST, Needs.Kind.ENERGY]
const ACCIDENT_MOOD := 10.0
const ACCIDENT_SOCIAL_PENALTY := 30.0
const CHANGE_CLOTHES_MINUTES := 20.0
const INJURY_TREATMENT_MINUTES := 45.0

var needs: Needs
var lineup: Lineup
var grounds: FestivalGrounds
var current_configuration: RunConfiguration
var run_seed := 0
var budget := STARTING_BUDGET
var score_ledger := ScoreLedger.new()
var facility_queue := FacilityQueue.new()
var food_poisoning := FoodPoisoning.new()
var tipsy := TipsyState.new()
var mosh := MoshState.new()
var mosh_genres := {}
var friends: Array[FestivalFriend] = []
var poisoning_roll_count := 0
var run_events: Array[RunEvent] = []
var run_status := RunStatus.NOT_STARTED
var _festival_maximum := 0.0
var _pending_vendor: Vendor
var _pending_vendor_item: VendorItem
var _collapsing := false
var _accident_penalty := false
var _changing_clothes := false
var _poison_rng := RandomNumberGenerator.new()
var _mosh_rng := RandomNumberGenerator.new()
var _treating_injury := false

func _ready() -> void:
	Clock.time_advanced.connect(_on_time_advanced)
	Clock.night_started.connect(_on_night_started)
	Clock.morning_started.connect(_on_morning_started)
	Clock.run_completed.connect(_on_run_completed)
	Clock.reset()

func _process(_delta: float) -> void:
	if not check_for_collapse():
		check_for_accident()

func start_new_run(configuration: RunConfiguration = null, seed_value := -1) -> void:
	if configuration != null:
		current_configuration = configuration
	elif current_configuration == null:
		current_configuration = _default_configuration()
	run_seed = seed_value if seed_value >= 0 else _new_seed()
	current_configuration.lock()
	needs = Needs.new()
	var genre_graph := GenreGraph.load_bundled()
	lineup = FestivalGenerator.generate(
		current_configuration,
		run_seed,
		GenreCatalog.load_bundled(),
		genre_graph)
	grounds = FestivalGroundsGenerator.generate(lineup, run_seed, current_configuration)
	friends = FriendGenerator.generate(current_configuration, lineup, grounds, genre_graph, run_seed)
	budget = STARTING_BUDGET
	score_ledger = ScoreLedger.new()
	facility_queue = FacilityQueue.new()
	food_poisoning = FoodPoisoning.new()
	tipsy = TipsyState.new()
	mosh = MoshState.new()
	mosh_genres = MoshPit.build_eligible_genres(genre_graph)
	poisoning_roll_count = 0
	_poison_rng.seed = run_seed ^ 0x504f49534f4e
	_mosh_rng.seed = run_seed ^ 0x4d4f5348504954
	_pending_vendor = null
	_pending_vendor_item = null
	run_events.clear()
	_collapsing = false
	_accident_penalty = false
	_changing_clothes = false
	_treating_injury = false
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
		var social_decay := 0.45 if current_configuration.friend_count == 0 else 1.0
		needs.decay(minutes, social_decay)
	var poisoning_events := food_poisoning.advance(minutes, needs)
	for event in poisoning_events:
		_record_poisoning_event(event)
	if tipsy.advance(minutes, needs):
		food_poisoning_status.emit("Tipsy effects have worn off.")
	if facility_queue.is_active():
		var message := facility_queue.advance(minutes, needs)
		if not message.is_empty():
			if _pending_vendor != null and _pending_vendor_item != null:
				var price := _pending_vendor.price_for(_pending_vendor_item)
				budget -= price
				if _pending_vendor_item is AlcoholItem:
					tipsy.consume(_pending_vendor_item)
				_pending_vendor_item.apply(needs, tipsy.gain_multiplier())
				_roll_food_poisoning(_pending_vendor_item)
				food_poisoning.enforce_mood(needs)
				message = "%s purchased for €%.2f." % [_pending_vendor_item.display_name, price]
				_pending_vendor = null
				_pending_vendor_item = null
			facility_queue_finished.emit(message)

func _roll_food_poisoning(item: VendorItem) -> void:
	if not item.is_food:
		return
	poisoning_roll_count += 1
	if FoodPoisoning.roll(item.poisoning_risk, _poison_rng):
		food_poisoning.schedule()

func _record_poisoning_event(event: String) -> void:
	match event:
		"onset":
			run_events.append(RunEvent.new("food_poisoning_onset", Clock.total_minutes, "Food Poisoning symptoms began"))
			food_poisoning_status.emit("Food Poisoning — find water and stay near toilets.")
		"urgent":
			run_events.append(RunEvent.new("food_poisoning_urgent", Clock.total_minutes, "Urgent toilet pressure"))
			food_poisoning_status.emit("Food Poisoning: urgent toilet pressure!")
		"recovered":
			run_events.append(RunEvent.new("food_poisoning_recovered", Clock.total_minutes, "Recovered from Food Poisoning"))
			food_poisoning_status.emit("Food Poisoning has passed.")

func check_for_collapse() -> bool:
	if _collapsing or needs == null or grounds == null or run_status != RunStatus.PLAYING:
		return false
	var failed: Array[int] = []
	for kind in COLLAPSE_NEEDS:
		if needs.is_empty(kind):
			failed.append(kind)
	if failed.is_empty():
		return false
	_collapsing = true
	if facility_queue.is_active():
		interrupt_facility_queue()
	var names := PackedStringArray()
	for kind in failed:
		names.append(Needs.NAMES[kind])
	run_events.append(RunEvent.new("collapse", Clock.total_minutes, ", ".join(names)))
	collapse_started.emit(failed[0])
	Clock.advance_game_minutes(COLLAPSE_MINUTES)
	for kind in failed:
		needs.adjust(kind, COLLAPSE_RESTORE - needs.get_value(kind))
	needs.adjust(Needs.Kind.MOOD, COLLAPSE_MOOD - needs.get_value(Needs.Kind.MOOD))
	var first_aid := grounds.points_of_kind(FestivalPoint.Kind.FIRST_AID)[0]
	player_relocation_requested.emit(first_aid.position)
	_collapsing = false
	collapse_completed.emit("Recovered at First Aid after collapsing from %s." % ", ".join(names))
	return true

func is_collapsed() -> bool:
	return _collapsing

func check_for_accident() -> bool:
	if _accident_penalty or needs == null or grounds == null or run_status != RunStatus.PLAYING:
		return false
	if not needs.is_empty(Needs.Kind.BLADDER):
		return false
	_accident_penalty = true
	needs.adjust(Needs.Kind.MOOD, ACCIDENT_MOOD - needs.get_value(Needs.Kind.MOOD))
	needs.set_social_penalty(ACCIDENT_SOCIAL_PENALTY)
	needs.adjust(Needs.Kind.BLADDER, 30.0)
	run_events.append(RunEvent.new(
		"bladder_accident", Clock.total_minutes, "Bladder accident; change clothes at camp"))
	bladder_accident_occurred.emit(
		"Bladder accident — Mood crashed and Social -%.0f until you change at camp." % ACCIDENT_SOCIAL_PENALTY)
	return true

func has_accident_penalty() -> bool:
	return _accident_penalty

func change_at_camp(player_position: Vector2) -> bool:
	if not _accident_penalty or _changing_clothes or grounds == null or grounds.camp == null:
		return false
	if player_position.distance_to(grounds.camp.interaction_position) > 90.0:
		return false
	_changing_clothes = true
	Clock.advance_game_minutes(CHANGE_CLOTHES_MINUTES)
	needs.set_social_penalty(0.0)
	_accident_penalty = false
	_changing_clothes = false
	clothes_changed.emit("Changed clothes at camp — Social penalty cleared.")
	return true

func is_action_locked() -> bool:
	return _collapsing or _changing_clothes or _treating_injury

func apply_friend_presence(
		minutes: float,
		nearby_count: int,
		shared_set_count: int,
		festival_set: FestivalSet) -> void:
	if minutes <= 0.0 or nearby_count <= 0:
		return
	var gain_multiplier := tipsy.gain_multiplier()
	needs.adjust(Needs.Kind.SOCIAL, 0.18 * nearby_count * minutes * gain_multiplier)
	needs.adjust(Needs.Kind.MOOD, 0.08 * nearby_count * minutes * gain_multiplier)
	if shared_set_count > 0 and festival_set != null:
		award_bonus(
			"Shared experience — %s" % festival_set.artist.name,
			0.12 * shared_set_count * minutes)

func apply_solo_crowd_atmosphere(minutes: float) -> void:
	if current_configuration.friend_count == 0 and minutes > 0.0:
		needs.adjust(Needs.Kind.SOCIAL, 0.10 * minutes * tipsy.gain_multiplier())

func available_mosh_set(player_position: Vector2) -> FestivalSet:
	if lineup == null:
		return null
	for stage in lineup.stages:
		var festival_set := lineup.active_set_for(stage, Clock.total_minutes)
		if MoshPit.is_available(festival_set, player_position, Clock.total_minutes, mosh_genres):
			return festival_set
	return null

func join_mosh(festival_set: FestivalSet, player_position: Vector2) -> bool:
	if is_action_locked() or facility_queue.is_active() \
			or not MoshPit.is_available(festival_set, player_position, Clock.total_minutes, mosh_genres):
		return false
	if not mosh.join(festival_set):
		return false
	run_events.append(RunEvent.new("mosh_joined", Clock.total_minutes, festival_set.artist.name))
	mosh_status.emit("Joined the Mosh Pit for %s — leave whenever you want." % festival_set.artist.name)
	return true

func leave_mosh() -> bool:
	if not mosh.is_active():
		return false
	var artist_name := mosh.active_set.artist.name
	mosh.leave()
	mosh_status.emit("Left the Mosh Pit for %s." % artist_name)
	return true

func advance_mosh(minutes: float, player_position: Vector2) -> void:
	if not mosh.is_active():
		return
	if not MoshPit.is_available(mosh.active_set, player_position, Clock.total_minutes, mosh_genres):
		leave_mosh()
		return
	var artist_name := mosh.active_set.artist.name
	var result := mosh.advance(minutes, needs, _mosh_rng)
	if result.bonus_points > 0.0:
		award_bonus("Mosh Pit — %s" % artist_name, result.bonus_points)
	if result.injured_now:
		run_events.append(RunEvent.new("injury", Clock.total_minutes, "Injured while moshing to %s" % artist_name))
		mosh_status.emit("Injured in the Mosh Pit — walking speed halved until First Aid.")

func treat_injury(player_position: Vector2) -> bool:
	if not mosh.injured or is_action_locked():
		return false
	var first_aid := grounds.points_of_kind(FestivalPoint.Kind.FIRST_AID)[0]
	if player_position.distance_to(first_aid.position) > 90.0:
		return false
	_treating_injury = true
	Clock.advance_game_minutes(INJURY_TREATMENT_MINUTES)
	mosh.treat(needs)
	_treating_injury = false
	run_events.append(RunEvent.new("injury_treated", Clock.total_minutes, "Treated at First Aid"))
	mosh_status.emit("Injury treated at First Aid — movement restored.")
	return true

func queue_preview(facility: FestivalPoint) -> float:
	if facility == null:
		return 0.0
	var density := CrowdField.density(lineup, facility.position, Clock.total_minutes)
	return FacilityQueue.duration_for(facility.kind, density)

func start_facility_queue(facility: FestivalPoint, player_position: Vector2) -> bool:
	if is_action_locked() or facility == null or player_position.distance_to(facility.position) > 90.0:
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
	if is_action_locked() or vendor == null or item == null or not vendor.archetype.menu.has(item):
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
	for kind in [FestivalPoint.Kind.WATER, FestivalPoint.Kind.TOILET, FestivalPoint.Kind.VENDOR,
			FestivalPoint.Kind.CAMP, FestivalPoint.Kind.FIRST_AID]:
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
