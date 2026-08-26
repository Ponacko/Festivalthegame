class_name AudioSettings
extends RefCounted
## Three persisted local mixer controls.

const DEFAULT_PATH := "user://audio_settings.cfg"
const BUS_NAMES := ["Music", "Ambience", "Effects"]

var path: String
var levels := {"Music": 0.8, "Ambience": 0.75, "Effects": 0.9}

func _init(p_path := DEFAULT_PATH) -> void:
	path = p_path

func set_level(bus_name: String, value: float) -> void:
	if not BUS_NAMES.has(bus_name):
		return
	levels[bus_name] = clampf(value, 0.0, 1.0)
	apply()

func apply() -> void:
	for bus_name in BUS_NAMES:
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0:
			var linear := float(levels[bus_name])
			AudioServer.set_bus_volume_db(index, -80.0 if linear <= 0.001 else linear_to_db(linear))

func save() -> bool:
	var config := ConfigFile.new()
	for bus_name in BUS_NAMES:
		config.set_value("volume", bus_name, levels[bus_name])
	return config.save(path) == OK

func load() -> bool:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		apply()
		return false
	for bus_name in BUS_NAMES:
		levels[bus_name] = clampf(float(config.get_value("volume", bus_name, levels[bus_name])), 0.0, 1.0)
	apply()
	return true
