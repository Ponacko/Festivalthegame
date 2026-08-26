class_name HighScoreStore
extends RefCounted
## Bounded atomic JSON table stored entirely on-device.

const DEFAULT_PATH := "user://high_scores.json"
const DEFAULT_LIMIT := 10

var path: String
var limit: int
var entries: Array[Dictionary] = []

func _init(p_path := DEFAULT_PATH, p_limit := DEFAULT_LIMIT) -> void:
	path = p_path
	limit = maxi(1, p_limit)

func load() -> bool:
	entries.clear()
	if not FileAccess.file_exists(path):
		return true
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		return false
	for value in parsed:
		if value is Dictionary and value.has("run_seed") and value.has("percentage"):
			entries.append(value)
	_sort_and_trim()
	return true

func insert(result: FinalResult) -> bool:
	entries.append(result.high_score_entry())
	_sort_and_trim()
	return save()

func save() -> bool:
	var temporary := "%s.tmp" % path
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(entries))
	file.close()
	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temporary := ProjectSettings.globalize_path(temporary)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute_path)
	return DirAccess.rename_absolute(absolute_temporary, absolute_path) == OK

func _sort_and_trim() -> void:
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a["percentage"]), float(b["percentage"])):
			return float(a["percentage"]) > float(b["percentage"])
		if not is_equal_approx(float(a["score"]), float(b["score"])):
			return float(a["score"]) > float(b["score"])
		if int(a["completed_at"]) != int(b["completed_at"]):
			return int(a["completed_at"]) < int(b["completed_at"])
		return int(a["run_seed"]) < int(b["run_seed"]))
	if entries.size() > limit:
		entries.resize(limit)
