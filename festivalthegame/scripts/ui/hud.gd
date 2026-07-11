extends CanvasLayer
## Debug HUD (slice 1): shows the festival clock, Run stats, and a bar per Need.
## Built in code to avoid hand-authoring a deep scene tree.

var _info: Label
var _enjoy: Label
var _bars := {}
var _enjoy_node: Node

func _ready() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	_info = Label.new()
	vbox.add_child(_info)

	_enjoy = Label.new()
	vbox.add_child(_enjoy)

	for k in Needs.ALL:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = Needs.NAMES[k]
		label.custom_minimum_size = Vector2(80, 0)
		row.add_child(label)
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = Needs.MAX
		bar.custom_minimum_size = Vector2(220, 18)
		bar.show_percentage = false
		row.add_child(bar)
		vbox.add_child(row)
		_bars[k] = bar

func _process(_delta: float) -> void:
	if Game.needs == null:
		return
	_info.text = "Day %d  %s   %s  x%.2f   Score %.0f   €%.0f   Mult x%.2f\n[tap: move]  [space: pause]  [ [ / ] : speed ]  [R: new run]" % [
		FestivalTime.day(Clock.total_minutes),
		FestivalTime.clock_string(Clock.total_minutes),
		("PAUSED" if Clock.paused else "playing"),
		Clock.time_scale,
		Game.enjoyment_score,
		Game.budget,
		Game.needs.enjoyment_multiplier(),
	]
	for k in Needs.ALL:
		_bars[k].value = Game.needs.get_value(k)

	if _enjoy_node == null:
		_enjoy_node = get_tree().get_first_node_in_group("enjoyment")
	if _enjoy_node != null:
		var stage_name: String = _enjoy_node.current_stage.display_name if _enjoy_node.current_stage != null else "—"
		_enjoy.text = "At: %s  [%s]   +%.2f / min" % [
			stage_name,
			Audience.zone_name(_enjoy_node.current_zone),
			_enjoy_node.current_rate,
		]
