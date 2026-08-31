extends Node
# owns: reading and writing the save file, save schema versioning
# does not own: the in-memory game state shape (see GameState)

const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://save.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> bool:
	var payload: Dictionary = {
		"save_version": SAVE_VERSION,
		"game_state": GameState.to_save_dict(),
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("save_manager: could not open %s for writing" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true

func load_game() -> bool:
	if not has_save():
		return false
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("save_manager: could not open %s for reading" % SAVE_PATH)
		return false
	var raw_text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw_text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("save_manager: save file did not parse to a dictionary")
		return false
	var payload: Dictionary = parsed
	payload = _migrate(payload)
	GameState.from_save_dict(payload.get("game_state", {}))
	return true

## migration stub. bumps old saves forward one version at a time.
## no versions predate SAVE_VERSION 1 yet, so this is a no-op until schema changes.
func _migrate(payload: Dictionary) -> Dictionary:
	var version: int = payload.get("save_version", 1)
	if version < SAVE_VERSION:
		push_warning("save_manager: save is older than expected, no migration path defined yet")
	return payload

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
