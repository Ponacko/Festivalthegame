extends Node
## Touch menu communicates markup, final prices, and item trade-offs.

var failures := 0
var selected_item: VendorItem

func _ready() -> void:
	Game.start_new_run(null, 1112)
	var vendor: Vendor = Game.grounds.vendors[0]
	var view: VendorView = load("res://scenes/vendor_menu.tscn").instantiate()
	add_child(view)
	view.purchase_requested.connect(func(_vendor: Vendor, item: VendorItem) -> void: selected_item = item)
	view.show_vendor(vendor)
	var text := view.rendered_text()
	check(text.contains("markup") and text.contains("€"), "menu shows location markup and final prices")
	check(text.contains("Mood") and text.contains("risk"), "menu previews item effects and poisoning risk")
	check(view.item_button_count() == vendor.archetype.menu.size(), "menu renders every archetype item")
	check(view.minimum_item_height() >= 48.0, "menu purchase actions are touch-sized")
	var first_button := view.get_node("Panel/Margin/Content/Items").get_child(0) as Button
	first_button.pressed.emit()
	check(selected_item == vendor.archetype.menu[0], "tapping an item requests that exact purchase")
	view.get_node("Panel/Margin/Content/Close").pressed.emit()
	check(not view.visible, "Vendor menu can be cancelled without purchasing")
	if failures == 0:
		print("ALL VENDOR SCENE TESTS PASSED")
	else:
		printerr("%d VENDOR SCENE TEST(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
