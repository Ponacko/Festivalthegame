class_name ScoreboardView
extends Control

signal new_run_requested

@onready var _body: Label = $Panel/Margin/Content/Scroll/Body

func _ready() -> void:
	$Panel/Margin/Content/NewRun.pressed.connect(func() -> void: new_run_requested.emit())

func show_result(result: FinalResult, high_scores: Array[Dictionary]) -> void:
	var lines := PackedStringArray([
		"FINAL SCORE  %.1f / %.1f  —  %.2f%%" % [result.total_score, result.theoretical_maximum, result.percentage],
		"", "BREAKDOWN", result.breakdown_text(), "", "WAR STORIES",
		"None — you made it through cleanly." if result.war_stories.is_empty() else "\n".join(result.war_stories),
		"", "LOCAL HIGH SCORES",
	])
	for index in range(high_scores.size()):
		var item := high_scores[index]
		lines.append("%d. %.2f%% — %.1f pts — seed %d — %s" % [
			index + 1, item["percentage"], item["score"], item["run_seed"], item["configuration"]])
	_body.text = "\n".join(lines)
	show()

func rendered_text() -> String:
	return _body.text
