class_name RecapView
extends Control

signal dismissed

@onready var _body: Label = $Panel/Margin/Content/Scroll/Body

func _ready() -> void:
	$Panel/Margin/Content/Continue.pressed.connect(func() -> void:
		hide()
		dismissed.emit())

func show_recap(recap: DayRecap) -> void:
	_body.text = recap.text() if recap != null else "No recap available."
	show()

func rendered_text() -> String:
	return _body.text
