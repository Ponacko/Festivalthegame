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
var _stage_views: Array[StageView] = []
var _friend_views: Array[FriendView] = []
var _planner_was_paused := false
var _map_was_paused := false
var _vendor_was_paused := false
var _chat_was_paused := false

func _ready() -> void:
	_setup.configuration_submitted.connect(_on_configuration_submitted)
	_hud.schedule_requested.connect(_open_schedule)
	_hud.pause_requested.connect(_toggle_pause)
	_hud.speed_requested.connect(_cycle_speed)
	_hud.map_requested.connect(_open_map)
	_hud.vendor_requested.connect(_open_vendor)
	_hud.chat_requested.connect(_open_chat)
	_schedule.closed.connect(_on_schedule_closed)
	_festival_map.closed.connect(_on_map_closed)
	_vendor_view.closed.connect(_on_vendor_closed)
	_vendor_view.purchase_requested.connect(_on_vendor_purchase_requested)
	_group_chat.closed.connect(_on_chat_closed)
	_group_chat.meet_requested.connect(_on_meet_requested)
	Game.player_relocation_requested.connect(_player.relocate_to)
	_open_setup()
	_spawn_stage_views()
	_spawn_ground_features()
	_spawn_friend_views()

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
	_setup.reset()
	_setup.show()

func _on_configuration_submitted(configuration: RunConfiguration) -> void:
	Game.start_new_run(configuration)
	_spawn_stage_views()
	_spawn_ground_features()
	_spawn_friend_views()
	_setup.hide()
	Clock.paused = false

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
	Clock.paused = true
	_vendor_view.show_vendor(vendor)

func _on_vendor_closed() -> void:
	Clock.paused = _vendor_was_paused

func _on_vendor_purchase_requested(vendor: Vendor, item: VendorItem) -> void:
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

func _toggle_pause() -> void:
	if not _setup.visible and not _schedule.visible and not _festival_map.visible and not _vendor_view.visible \
			and not _group_chat.visible:
		Clock.toggle_paused()

func _cycle_speed() -> void:
	if not _setup.visible and not _schedule.visible and not _festival_map.visible and not _vendor_view.visible \
			and not _group_chat.visible:
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
