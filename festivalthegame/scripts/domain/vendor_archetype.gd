class_name VendorArchetype
extends RefCounted
## Reusable Vendor identity and menu.

var id: String
var display_name: String
var menu: Array[VendorItem]

func _init(p_id: String, p_name: String, p_menu: Array[VendorItem]) -> void:
	id = p_id
	display_name = p_name
	menu = p_menu
