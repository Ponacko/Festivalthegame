extends Node2D
## Root of the playable scene. Spawns a StageView per Stage in the current
## Lineup and handles dev hotkeys; gameplay lives in the autoloads and child nodes.

@onready var _setup: RunSetupView = $SetupLayer/RunSetup
@onready var _hud: CanvasLayer = $Hud
@onready var _schedule: ScheduleView = $PlannerLayer/Schedule
@onready var _festival_map: FestivalMapView = $MapLayer/FestivalMap
@onready var _player: Node2D = $Player
@onready var _vendor_view: VendorView = $VendorLayer/VendorMenu
@onready var _group_chat: GroupChatView = $ChatLayer/GroupChat
@onready var _night_view: NightView = $NightLayer/Night
@onready var _recap_view: RecapView = $RecapLayer/Recap
@onready var _scoreboard: ScoreboardView = $ScoreboardLayer/Scoreboard
@onready var _soundscape: FestivalSoundscape = $Soundscape
@onready var _audio_settings: AudioSettingsView = $AudioLayer/AudioSettings
var _stage_views: Array[StageView] = []
var _friend_views: Array[FriendView] = []
var _planner_was_paused := false
var _map_was_paused := false
var _vendor_was_paused := false
var _chat_was_paused := false
var _vendor_from_night := false
var _ironman_save := IronmanSave.new()
var _audio_was_paused := false

func _ready() -> void:
	_setup.configuration_submitted.connect(_on_configuration_submitted)
	_setup.resume_requested.connect(_resume_active_run)
	_hud.schedule_requested.connect(_open_schedule)
	_hud.pause_requested.connect(_toggle_pause)
	_hud.speed_requested.connect(_cycle_speed)
	_hud.map_requested.connect(_open_map)
	_hud.vendor_requested.connect(_open_vendor)
	_hud.chat_requested.connect(_open_chat)
	_hud.audio_settings_requested.connect(_open_audio_settings)
	_schedule.closed.connect(_on_schedule_closed)
	_festival_map.closed.connect(_on_map_closed)
	_vendor_view.closed.connect(_on_vendor_closed)
	_vendor_view.purchase_requested.connect(_on_vendor_purchase_requested)
	_group_chat.closed.connect(_on_chat_closed)
	_group_chat.meet_requested.connect(_on_meet_requested)
	_night_view.party_requested.connect(_on_night_party)
	_night_view.sleep_requested.connect(_on_night_sleep)
	_night_view.late_food_requested.connect(_open_vendor)
	Game.night_choices_requested.connect(_open_night)
	Game.morning_recap_requested.connect(_open_recap)
	_recap_view.dismissed.connect(_on_recap_dismissed)
	Game.final_scoring_requested.connect(_open_scoreboard)
	Game.autosave_requested.connect(func(_reason: String) -> void: _write_autosave())
	Clock.minute_ticked.connect(func(_minute: int) -> void: _write_autosave())
	Game.run_completed.connect(func() -> void: _ironman_save.clear())
	_scoreboard.new_run_requested.connect(_open_setup)
	_audio_settings.closed.connect(_on_audio_settings_closed)
	Game.player_relocation_requested.connect(_player.relocate_to)
	_open_setup()
	_spawn_stage_views()
	_spawn_ground_features()
	_spawn_friend_views()
	_soundscape.build_for_lineup()

func _spawn_stage_views() -> void:
	for view in _stage_views:
		view.queue_free()
	_stage_views.clear()
	if Game.lineup == null:
		return
	for stage in Game.lineup.stages:
		var view := StageView.new()
		view.setup(stage)
		add_child(view)
		_stage_views.append(view)

func _spawn_ground_features() -> void:
	for child in $GroundFeatures.get_children():
		child.queue_free()
	if Game.grounds == null:
		return
	_player.configure_camera(Game.grounds.bounds)
	for point in Game.grounds.points:
		if point.kind == FestivalPoint.Kind.STAGE:
			continue
		var view := GroundFeatureView.new()
		view.setup(point)
		$GroundFeatures.add_child(view)
	for obstacle in Game.grounds.obstacles:
		var body := StaticBody2D.new()
		body.position = obstacle.get_center()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = obstacle.size
		collision.shape = shape
		body.add_child(collision)
		$GroundFeatures.add_child(body)

func _spawn_friend_views() -> void:
	for view in _friend_views:
		view.queue_free()
	_friend_views.clear()
	for friend in Game.friends:
		var view := FriendView.new()
		view.setup(friend, Game.grounds)
		$FriendViews.add_child(view)
		_friend_views.append(view)

func _open_setup() -> void:
	Clock.paused = true
	_schedule.hide()
	_festival_map.hide()
	_vendor_view.hide()
	_group_chat.hide()
	_night_view.hide()
	_recap_view.hide()
	_scoreboard.hide()
	_audio_settings.hide()
	_setup.reset()
	_setup.set_active_save_available(_ironman_save.has_active_run())
	_setup.show()

func _on_configuration_submitted(configuration: RunConfiguration) -> void:
	Game.start_new_run(configuration)
	_spawn_stage_views()
	_spawn_ground_features()
	_spawn_friend_views()
	_soundscape.build_for_lineup()
	_setup.hide()
	Clock.paused = false
	_write_autosave()

func _resume_active_run() -> void:
	var snapshot := _ironman_save.load_snapshot()
	if snapshot.is_empty():
		_setup.get_node("Panel/Margin/Content/Error").text = _ironman_save.last_error
		return
	var restored := Game.restore_snapshot(snapshot)
	if restored.is_empty():
		_setup.get_node("Panel/Margin/Content/Error").text = "The active Run could not be restored safely. Start a new Run to recover."
		return
	_spawn_stage_views()
	_spawn_ground_features()
	_spawn_friend_views()
	_soundscape.build_for_lineup()
	_player.relocate_to(restored["player_position"])
	_setup.hide()
	if Game.night.active:
		_open_night(Game.night.day)
	elif Game.pending_recap != null:
		_open_recap(Game.pending_recap.day)
	else:
		Clock.paused = bool(snapshot.get("paused", false))

func _write_autosave() -> void:
	if Game.run_status == Game.RunStatus.PLAYING and Game.needs != null:
		_ironman_save.save(Game.snapshot(_player.global_position))

func _open_audio_settings() -> void:
	if _setup.visible or _audio_settings.visible:
		return
	_audio_was_paused = Clock.paused
	Clock.paused = true
	_audio_settings.show_settings(_soundscape.settings)

func _on_audio_settings_closed() -> void:
	Clock.paused = _audio_was_paused

func _open_schedule() -> void:
	if Game.lineup == null or _setup.visible or _vendor_view.visible or Game.facility_queue.is_active():
		return
	_planner_was_paused = Clock.paused
	Clock.paused = true
	_schedule.show_schedule(Game.lineup, FestivalTime.day(Clock.total_minutes))

func _on_schedule_closed() -> void:
	Clock.paused = _planner_was_paused

func _open_map() -> void:
	if Game.grounds == null or _setup.visible or _schedule.visible or _vendor_view.visible \
			or Game.facility_queue.is_active():
		return
	_map_was_paused = Clock.paused
	Clock.paused = true
	_festival_map.show_map(Game.grounds, _player)

func _on_map_closed() -> void:
	Clock.paused = _map_was_paused

func _open_vendor(vendor: Vendor) -> void:
	if vendor == null or _setup.visible or _schedule.visible or _festival_map.visible \
			or Game.facility_queue.is_active():
		return
	_vendor_was_paused = Clock.paused
	_vendor_from_night = _night_view.visible
	if _vendor_from_night:
		_night_view.hide()
	Clock.paused = true
	_vendor_view.show_vendor(vendor)

func _on_vendor_closed() -> void:
	Clock.paused = _vendor_was_paused
	if _vendor_from_night and Game.night.active:
		_night_view.show_night(Game.night, Game.grounds.camp, Game.late_night_vendors())
	_vendor_from_night = false

func _on_vendor_purchase_requested(vendor: Vendor, item: VendorItem) -> void:
	if _vendor_from_night:
		if Game.complete_late_vendor_purchase(vendor, item):
			_vendor_view.set_status("Purchased %s. Night time passed while Queueing." % item.display_name)
		else:
			_vendor_view.set_status("Not enough Budget for that late-night purchase.")
		return
	if Game.start_vendor_purchase(vendor, item, _player.global_position):
		_vendor_view.hide()
		Clock.paused = _vendor_was_paused
	else:
		_vendor_view.set_status("Not enough Budget or move closer to this Vendor.")

func _open_chat() -> void:
	if Game.grounds == null or _setup.visible or _schedule.visible or _festival_map.visible \
			or _vendor_view.visible or Game.facility_queue.is_active():
		return
	_chat_was_paused = Clock.paused
	Clock.paused = true
	_group_chat.show_chat(Game.friends, Game.grounds)

func _on_chat_closed() -> void:
	Clock.paused = _chat_was_paused

func _on_meet_requested(friend: FestivalFriend, destination: FestivalPoint) -> void:
	var position := friend.camp_position
	for view in _friend_views:
		if view.friend == friend:
			position = view.global_position
			break
	var response := Game.request_friend_meet(friend, destination, position)
	_group_chat.show_response(response.message)

func _open_night(_day: int) -> void:
	Clock.paused = true
	_night_view.show_night(Game.night, Game.grounds.camp, Game.late_night_vendors())

func _on_night_party() -> void:
	Game.party_for_hour()
	if Game.night.active:
		_night_view.show_night(Game.night, Game.grounds.camp, Game.late_night_vendors())

func _on_night_sleep() -> void:
	if Game.sleep_until_morning():
		_night_view.hide()

func _open_recap(_day: int) -> void:
	Clock.paused = true
	_night_view.hide()
	_recap_view.show_recap(Game.pending_recap)

func _on_recap_dismissed() -> void:
	Game.dismiss_recap()
	Clock.paused = false

func _open_scoreboard() -> void:
	Clock.paused = true
	_recap_view.hide()
	_scoreboard.show_result(Game.final_result, Game.high_scores.entries)

func _toggle_pause() -> void:
	if not _setup.visible and not _schedule.visible and not _festival_map.visible and not _vendor_view.visible \
			and not _group_chat.visible and not _night_view.visible and not _recap_view.visible:
		Clock.toggle_paused()

func _cycle_speed() -> void:
	if not _setup.visible and not _schedule.visible and not _festival_map.visible and not _vendor_view.visible \
			and not _group_chat.visible and not _night_view.visible and not _recap_view.visible:
		Clock.cycle_time_scale()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_toggle_pause()
			KEY_R:
				_open_setup()
			KEY_BRACKETRIGHT:
				Clock.cycle_time_scale(1)
			KEY_BRACKETLEFT:
				Clock.cycle_time_scale(-1)
