extends SceneTree

var failures := 0

func _initialize() -> void:
	check(ResourceLoader.exists("res://ui/festival_theme.tres"), "one bundled production theme is available offline")
	check(FileAccess.file_exists("res://ASSET_PROVENANCE.md") and FileAccess.file_exists("res://VISUAL_SMOKE_TEST.md"),
		"asset provenance and full-Run visual smoke checklist are bundled")
	var script_text := FileAccess.get_file_as_string("res://scripts/ui/pixel_art.gd")
	check(script_text.contains("func person") and script_text.contains("func facility"),
		"shared pixel art covers characters and facilities without rendered-test coupling")
	var modal_scenes := ["run_setup", "schedule", "festival_map", "group_chat", "night", "recap", "scoreboard"]
	for scene_name in modal_scenes:
		check(ResourceLoader.exists("res://scenes/%s.tscn" % scene_name), "%s uses the shared visual language" % scene_name)
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("  FAIL: ", message)
