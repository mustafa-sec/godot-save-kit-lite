# MIT License — Copyright (c) 2026 Fortress MSSP LLC. See LICENSE.
class_name GSKLite
extends RefCounted

const _PATH = "user://godot_save_kit_lite.json"
const _TEMP = _PATH + ".tmp"
const _LIMIT = 8 * 1024 * 1024

# Ancestor identity detects cycles without rejecting shared non-cyclic containers.
static func _valid(value: Variant, depth: int = 0, ancestors: Array = []) -> bool:
	if depth > 64:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_FLOAT:
			return is_finite(value)
		TYPE_ARRAY, TYPE_DICTIONARY:
			for ancestor in ancestors:
				if is_same(value, ancestor):
					return false
			var chain = ancestors.duplicate()
			chain.append(value)
			if value is Dictionary:
				for key in value:
					if not key is String or not _valid(value[key], depth + 1, chain):
						return false
			else:
				for item in value:
					if not _valid(item, depth + 1, chain):
						return false
			return true
	return false

static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"error": ERR_FILE_NOT_FOUND, "value": null}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": FileAccess.get_open_error(), "value": null}
	if file.get_length() > _LIMIT:
		return {"error": ERR_INVALID_DATA, "value": null}
	var text = file.get_as_text()
	var error = file.get_error()
	file.close()
	if error != OK and error != ERR_FILE_EOF:
		return {"error": error, "value": null}
	var json = JSON.new()
	if json.parse(text) != OK:
		return {"error": ERR_INVALID_DATA, "value": null}
	return {"error": OK, "value": json.data}

static func _version(value: Variant) -> int:
	if not value is Dictionary:
		return 0
	var version: Variant = value.get("version")
	if not (version is int or version is float):
		return 0
	if not is_finite(float(version)) or version < 1 or floor(float(version)) != float(version):
		return 0
	return 1 if version == 1 else 2

static func _decode(result: Dictionary) -> Dictionary:
	var error: int = result.error
	if error == OK:
		var version = _version(result.value)
		if version == 0 or not result.value.get("data") is Dictionary or not _valid(result.value.data):
			error = ERR_INVALID_DATA
		elif version != 1:
			error = ERR_UNAVAILABLE
	if error != OK:
		return {"error": error, "data": {}}
	return {"error": OK, "data": result.value.data}

static func save_data(data: Dictionary) -> Error:
	if not _valid(data):
		return ERR_INVALID_DATA
	var text = JSON.stringify({"version": 1, "data": data})
	if text.to_utf8_buffer().size() > _LIMIT:
		return ERR_INVALID_DATA
	if has_save():
		var old = _read(_PATH)
		if old.error != OK and old.error != ERR_INVALID_DATA:
			return old.error
		if old.error == OK and _version(old.value) == 2:
			return ERR_UNAVAILABLE
	var file = FileAccess.open(_TEMP, FileAccess.WRITE)
	if file == null:
		var error = FileAccess.get_open_error()
		_clean_temp()
		return error
	file.store_string(text)
	file.flush()
	var error = file.get_error()
	file.close()
	if error == OK:
		error = _decode(_read(_TEMP)).error
	if error == OK:
		error = DirAccess.rename_absolute(_TEMP, _PATH)
	if error != OK:
		_clean_temp()
	return error

static func _clean_temp() -> void:
	if FileAccess.file_exists(_TEMP):
		DirAccess.remove_absolute(_TEMP)

static func load_data() -> Dictionary:
	return _decode(_read(_PATH))

static func has_save() -> bool:
	return FileAccess.file_exists(_PATH)

static func delete() -> Error:
	var found = false
	for path in [_PATH, _TEMP]:
		if FileAccess.file_exists(path):
			found = true
			var error = DirAccess.remove_absolute(path)
			if error != OK:
				return error
	return OK if found else ERR_DOES_NOT_EXIST
