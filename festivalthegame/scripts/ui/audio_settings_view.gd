class_name AudioSettingsView
extends Control

signal closed

var settings: AudioSettings

func _ready() -> void:
	$Panel/Margin/Content/Music.value_changed.connect(func(value: float) -> void: _change("Music", value))
	$Panel/Margin/Content/Ambience.value_changed.connect(func(value: float) -> void: _change("Ambience", value))
	$Panel/Margin/Content/Effects.value_changed.connect(func(value: float) -> void: _change("Effects", value))
	$Panel/Margin/Content/Close.pressed.connect(func() -> void:
		settings.save()
		hide()
		closed.emit())

func show_settings(value: AudioSettings) -> void:
	settings = value
	$Panel/Margin/Content/Music.value = settings.levels["Music"] * 100.0
	$Panel/Margin/Content/Ambience.value = settings.levels["Ambience"] * 100.0
	$Panel/Margin/Content/Effects.value = settings.levels["Effects"] * 100.0
	show()

func _change(bus_name: String, value: float) -> void:
	if settings != null:
		settings.set_level(bus_name, value / 100.0)
