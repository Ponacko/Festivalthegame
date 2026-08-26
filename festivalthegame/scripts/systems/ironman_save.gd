class_name IronmanSave
extends RefCounted
## One versioned, atomic active-Run save; no slots or seed retry surface.

const SCHEMA_VERSION := 1
const DEFAULT_PATH := "user://active_run.json"

var path: String
var last_error := ""

func _init(p_path := DEFAULT_PATH) -> void:
	path = p_path

func has_active_run() -> bool:
	return FileAccess.file_exists(path)

func save(snapshot: Dictionary) -> bool:
	var envelope := {"schema": SCHEMA_VERSION, "run": snapshot}
	var temporary := "%s.tmp" % path
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "Unable to create the active Run autosave."
		return false
	file.store_string(JSON.stringify(envelope))
	file.close()
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)
	var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), absolute)
	last_error = "" if error == OK else "Unable to replace the active Run autosave atomically."
	return error == OK

func load_snapshot() -> Dictionary:
	last_error = ""
	if not has_active_run():
		last_error = "No active Run is available."
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parser := JSON.new()
	var parsed = null
	if file != null and parser.parse(file.get_as_text()) == OK:
		parsed = parser.data
	if not parsed is Dictionary or int(parsed.get("schema", -1)) != SCHEMA_VERSION or not parsed.get("run") is Dictionary:
		last_error = "The active Run is corrupt or incompatible. Start a new Run to recover."
		return {}
	return parsed["run"]

func clear() -> bool:
	if not has_active_run():
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK
