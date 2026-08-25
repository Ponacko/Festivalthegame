class_name VendorView
extends Control
## Touch menu showing location-adjusted prices before purchase.

signal closed
signal purchase_requested(vendor: Vendor, item: VendorItem)

@onready var _title: Label = $Panel/Margin/Content/Title
@onready var _items: VBoxContainer = $Panel/Margin/Content/Items
@onready var _status: Label = $Panel/Margin/Content/Status
var _vendor: Vendor
var _buttons: Array[Button] = []

func _ready() -> void:
	$Panel/Margin/Content/Close.pressed.connect(_on_close)

func show_vendor(vendor: Vendor) -> void:
	_vendor = vendor
	_title.text = "%s  •  location markup x%.2f" % [vendor.archetype.display_name, vendor.markup]
	_status.text = "Budget €%.2f  •  Queue %.1f min" % [Game.budget, Game.vendor_queue_preview(vendor)]
	for child in _items.get_children():
		child.queue_free()
	_buttons.clear()
	for item in vendor.archetype.menu:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 58)
		button.text = "%s  €%.2f\n%s" % [item.display_name, vendor.price_for(item), item.effect_summary()]
		button.pressed.connect(_on_item_pressed.bind(item))
		_items.add_child(button)
		_buttons.append(button)
	show()

func set_status(message: String) -> void:
	_status.text = message

func rendered_text() -> String:
	var parts := PackedStringArray([_title.text, _status.text])
	for button in _buttons:
		parts.append(button.text)
	return "\n".join(parts)

func item_button_count() -> int:
	return _buttons.size()

func minimum_item_height() -> float:
	return 0.0 if _buttons.is_empty() else _buttons[0].custom_minimum_size.y

func _on_item_pressed(item: VendorItem) -> void:
	purchase_requested.emit(_vendor, item)

func _on_close() -> void:
	hide()
	closed.emit()
