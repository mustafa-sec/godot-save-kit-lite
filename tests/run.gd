extends SceneTree
const Save = preload("res://addons/savekit_lite/savekit_lite.gd")
const PATH = "user://godot_save_kit_lite.json"
var failures = 0
var checks = 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label)
func write(text: String, path: String = PATH) -> void:
	var f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
func _initialize() -> void:
	# WARNING: tests delete the fixed Lite save in this project user directory.
	Save.delete()
	check(Save.load_data().error == ERR_FILE_NOT_FOUND, "missing file")
	var data = {"nested": {"items": [1, true, null, {"name": "星 café 😀"}]}}
	check(Save.save_data(data) == OK, "save nested unicode")
	check(Save.load_data().data == JSON.parse_string(JSON.stringify(data)), "round trip nested unicode")
	var f = FileAccess.open(PATH, FileAccess.READ)
	check(JSON.parse_string(f.get_as_text()).version == 1, "version field")
	f.close()
	check(not FileAccess.file_exists(PATH + ".tmp"), "no leftover temp")
	check(Save.save_data({}) == OK and Save.load_data().data == {}, "empty dictionary")
	check(Save.save_data({"vector": Vector2.ONE}) == ERR_INVALID_DATA, "unsupported Variant")
	check(Save.save_data({1: "bad"}) == ERR_INVALID_DATA, "non-string key")
	check(Save.save_data({"nan": NAN}) == ERR_INVALID_DATA, "non-finite number")
	var cycle = []
	cycle.append(cycle)
	check(Save.save_data({"cycle": cycle}) == ERR_INVALID_DATA, "cycle")
	cycle.clear()
	var deep = {}
	var cursor = deep
	for i in range(66):
		cursor["next"] = {}
		cursor = cursor.next
	check(Save.save_data(deep) == ERR_INVALID_DATA, "depth cap")
	check(Save.save_data({"large": "x".repeat(8 * 1024 * 1024)}) == ERR_INVALID_DATA, "size cap")
	write("{broken")
	check(Save.load_data().error == ERR_INVALID_DATA, "corrupt JSON no crash")
	check(Save.save_data({"old": true}) == OK, "explicit corrupt replacement")
	# Inject temp-open failure by placing a directory at the owned temp path.
	DirAccess.make_dir_absolute(PATH + ".tmp")
	check(Save.save_data({"new": true}) != OK, "injected temp-open failure")
	check(Save.load_data().data == {"old": true}, "failure preserves old primary")
	DirAccess.remove_absolute(PATH + ".tmp")
	write('{"version":2,"data":{}}')
	check(Save.load_data().error == ERR_UNAVAILABLE, "future load rejected")
	check(Save.save_data({}) == ERR_UNAVAILABLE, "future overwrite blocked")
	for text in ['{}', '{"version":0,"data":{}}', '{"version":1,"data":[]}', '[]']:
		write(text)
		check(Save.load_data().error == ERR_INVALID_DATA, "invalid envelope " + text)
	check(Save.delete() == OK and not Save.has_save(), "delete primary")
	write('{"version":1,"data":{"stale":true}}', PATH + ".tmp")
	check(not Save.has_save() and Save.load_data().error == ERR_FILE_NOT_FOUND, "stale temp ignored")
	check(Save.delete() == OK and not FileAccess.file_exists(PATH + ".tmp"), "delete temp")
	check(Save.delete() == ERR_DOES_NOT_EXIST, "delete absent")
	print("RESULT %s checks / %s failures" % [checks, failures])
	quit(1 if failures else 0)
