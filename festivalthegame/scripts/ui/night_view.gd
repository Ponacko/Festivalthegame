class_name NightView
extends Control
## Touch-first overnight choices; every action states its time cost.

signal party_requested
signal sleep_requested
signal late_food_requested(vendor: Vendor)

@onready var _summary: Label = $Panel/Margin/Content/Summary
@onready var _food: OptionButton = $Panel/Margin/Content/LateFood

func _ready() -> void:
	$Panel/Margin/Content/Party.pressed.connect(func() -> void: party_requested.emit())
	$Panel/Margin/Content/Sleep.pressed.connect(func() -> void: sleep_requested.emit())
	$Panel/Margin/Content/BuyFood.pressed.connect(_request_food)

func show_night(night: NightState, camp: Camp, vendors: Array[Vendor]) -> void:
	_food.clear()
	for vendor in vendors:
		_food.add_item(vendor.archetype.display_name)
	$Panel/Margin/Content/BuyFood.disabled = vendors.is_empty()
	_summary.text = "Night %d at %s\nSleep quality %.0f%%  •  Noise %.0f%%  •  Nightlife %.0f%%\nPartied %.0f min  •  Slept %.0f min" % [
		night.day, camp.profile.display_name, camp.profile.sleep_quality * 100.0,
		camp.profile.noise * 100.0, camp.profile.nightlife * 100.0,
		night.party_minutes, night.sleep_minutes]
	show()

func _request_food() -> void:
	var vendors := Game.late_night_vendors()
	if not vendors.is_empty():
		late_food_requested.emit(vendors[_food.selected])
