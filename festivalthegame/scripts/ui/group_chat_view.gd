class_name GroupChatView
extends Control
## Read-only group status plus the single intentional meet command.

signal closed
signal meet_requested(friend: FestivalFriend, destination: FestivalPoint)

var _friends: Array[FestivalFriend] = []
var _grounds: FestivalGrounds
@onready var _plans: Label = $Panel/Margin/Content/Plans
@onready var _friend_picker: OptionButton = $Panel/Margin/Content/Friend
@onready var _destination_picker: OptionButton = $Panel/Margin/Content/Destination
@onready var _send: Button = $Panel/Margin/Content/Send
@onready var _response: Label = $Panel/Margin/Content/Response

func _ready() -> void:
	$Panel/Margin/Content/Close.pressed.connect(_close)
	_friend_picker.item_selected.connect(func(_index: int) -> void: _update_send_text())
	_destination_picker.item_selected.connect(func(_index: int) -> void: _update_send_text())
	_send.pressed.connect(_send_request)

func show_chat(friends: Array[FestivalFriend], grounds: FestivalGrounds) -> void:
	_friends = friends
	_grounds = grounds
	_friend_picker.clear()
	for friend in _friends:
		_friend_picker.add_item(friend.display_name)
	_destination_picker.clear()
	if _grounds != null:
		for point in _grounds.points:
			_destination_picker.add_item(point.display_name)
	_response.text = ""
	refresh()
	show()

func refresh() -> void:
	var sections := PackedStringArray()
	for friend in _friends:
		sections.append("%s\nLocation: %s\nActivity: %s\nNext: %s" % [
			friend.display_name,
			friend.current_location_name(Clock.total_minutes, _grounds),
			friend.current_activity(Clock.total_minutes, _grounds),
			friend.next_set_summary(Clock.total_minutes),
		])
	_plans.text = "\n\n".join(sections)
	_update_send_text()

func rendered_text() -> String:
	return _plans.text

func destination_count() -> int:
	return _destination_picker.item_count

func show_response(message: String) -> void:
	_response.text = message
	refresh()

func _update_send_text() -> void:
	if _destination_picker.item_count == 0:
		_send.text = "Meet me at X"
		_send.disabled = true
		return
	_send.disabled = _friend_picker.item_count == 0
	_send.text = "Meet me at %s" % _destination_picker.get_item_text(_destination_picker.selected)

func _send_request() -> void:
	if _friends.is_empty() or _grounds == null or _grounds.points.is_empty():
		return
	meet_requested.emit(_friends[_friend_picker.selected], _grounds.points[_destination_picker.selected])

func _close() -> void:
	hide()
	closed.emit()
