class_name VendorCatalog
extends RefCounted
## Bundled v1 food and non-alcoholic drink archetypes.

static func all_archetypes() -> Array[VendorArchetype]:
	var bar_menu: Array[VendorItem] = [
		AlcoholItem.new("lager", "Sunset Lager", 5.0, 6.0, 6.0, -16.0, 0.20, 60.0),
		AlcoholItem.new("cider", "Apple Cider", 6.0, 8.0, 5.0, -14.0, 0.25, 75.0),
		AlcoholItem.new("cocktail", "Neon Cocktail", 9.0, 12.0, 8.0, -20.0, 0.40, 90.0),
	]
	return [
		VendorArchetype.new("quick_bites", "Quick Bites", [
			VendorItem.new("fries", "Festival Fries", 5.0, {Needs.Kind.HUNGER: 24.0}, 5.0, 0.06, true),
			VendorItem.new("wrap", "Veggie Wrap", 8.0, {Needs.Kind.HUNGER: 38.0}, 3.0, 0.02, true),
			VendorItem.new("lemonade", "Lemonade", 4.0,
				{Needs.Kind.THIRST: 28.0, Needs.Kind.BLADDER: -9.0}, 2.0, 0.0, false),
		]),
		VendorArchetype.new("fresh_field", "Fresh Field Kitchen", [
			VendorItem.new("apple", "Apple & Oat Cup", 4.0, {Needs.Kind.HUNGER: 18.0}, 1.0, 0.01, true),
			VendorItem.new("rice_bowl", "Festival Rice Bowl", 10.0, {Needs.Kind.HUNGER: 48.0}, 4.0, 0.03, true),
			VendorItem.new("juice", "Fruit Juice", 5.0,
				{Needs.Kind.THIRST: 24.0, Needs.Kind.BLADDER: -7.0}, 3.0, 0.01, false),
		]),
		VendorArchetype.new("camp_cafe", "Camp Café", [
			VendorItem.new("toastie", "Cheese Toastie", 7.0, {Needs.Kind.HUNGER: 32.0}, 4.0, 0.04, true),
			VendorItem.new("coffee", "Iced Coffee", 5.0,
				{Needs.Kind.THIRST: 12.0, Needs.Kind.ENERGY: 18.0, Needs.Kind.BLADDER: -11.0}, 3.0, 0.0, false),
			VendorItem.new("soda", "Festival Soda", 4.0,
				{Needs.Kind.THIRST: 20.0, Needs.Kind.BLADDER: -10.0}, 4.0, 0.0, false),
		]),
		VendorArchetype.new("festival_bar", "Festival Bar", bar_menu),
	]
