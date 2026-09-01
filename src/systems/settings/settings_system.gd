class_name SettingsSystem
extends RefCounted
# owns: persisting and applying player-facing settings (volume, text speed, key bindings) to
#   a separate user://settings.json file, independent of the gameplay save (see SaveManager)
# does not own: the settings menu UI (see SettingsMenuController), the dialogue reveal loop
#   itself (see DialogueBoxController), which only reads get_text_speed_multiplier()

const SETTINGS_PATH: String = "user://settings.json"
const MIN_TEXT_SPEED_MULTIPLIER: float = 1.0
const MAX_TEXT_SPEED_MULTIPLIER: float = 2.5

const REBINDABLE_ACTIONS: Array[String] = [
	"move_up", "move_down", "move_left", "move_right",
	"interact", "advance_dialogue", "skip_text", "open_map", "pause",
]

static var _loaded: bool = false
static var _master_volume: float = 1.0
static var _music_volume: float = 1.0
static var _sfx_volume: float = 1.0
static var _text_speed_multiplier: float = MIN_TEXT_SPEED_MULTIPLIER
static var _key_bindings: Dictionary = {}

static func get_master_volume() -> float:
	_ensure_loaded()
	return _master_volume

static func get_music_volume() -> float:
	_ensure_loaded()
	return _music_volume

static func get_sfx_volume() -> float:
	_ensure_loaded()
	return _sfx_volume

## never below MIN_TEXT_SPEED_MULTIPLIER, per STORY.md's "slow default" pacing floor;
## settings can only speed dialogue up, never slow it below the authored rate.
static func get_text_speed_multiplier() -> float:
	_ensure_loaded()
	return _text_speed_multiplier

static func set_master_volume(value: float) -> void:
	_ensure_loaded()
	_master_volume = clampf(value, 0.0, 1.0)
	_apply_audio()

static func set_music_volume(value: float) -> void:
	_ensure_loaded()
	_music_volume = clampf(value, 0.0, 1.0)
	_apply_audio()

static func set_sfx_volume(value: float) -> void:
	_ensure_loaded()
	_sfx_volume = clampf(value, 0.0, 1.0)
	_apply_audio()

static func set_text_speed_multiplier(value: float) -> void:
	_ensure_loaded()
	_text_speed_multiplier = clampf(value, MIN_TEXT_SPEED_MULTIPLIER, MAX_TEXT_SPEED_MULTIPLIER)

static func get_key_binding(action_name: String) -> int:
	_ensure_loaded()
	return _key_bindings.get(action_name, -1)

## rebinds an action's primary key. joypad events on the action, if any, are left untouched.
static func rebind_key(action_name: String, physical_keycode: int) -> void:
	_ensure_loaded()
	if not REBINDABLE_ACTIONS.has(action_name):
		push_error("settings_system: '%s' is not rebindable" % action_name)
		return
	_key_bindings[action_name] = physical_keycode
	_apply_key_binding(action_name, physical_keycode)

static func apply_all() -> void:
	_ensure_loaded()
	_apply_audio()
	for action_name: String in _key_bindings:
		_apply_key_binding(action_name, _key_bindings[action_name])

static func save() -> void:
	_ensure_loaded()
	var payload: Dictionary = {
		"master_volume": _master_volume,
		"music_volume": _music_volume,
		"sfx_volume": _sfx_volume,
		"text_speed_multiplier": _text_speed_multiplier,
		"key_bindings": _key_bindings,
	}
	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("settings_system: could not open %s for writing" % SETTINGS_PATH)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var payload: Dictionary = parsed
	_master_volume = payload.get("master_volume", 1.0)
	_music_volume = payload.get("music_volume", 1.0)
	_sfx_volume = payload.get("sfx_volume", 1.0)
	_text_speed_multiplier = clampf(
		payload.get("text_speed_multiplier", MIN_TEXT_SPEED_MULTIPLIER),
		MIN_TEXT_SPEED_MULTIPLIER, MAX_TEXT_SPEED_MULTIPLIER
	)
	_key_bindings = payload.get("key_bindings", {})

static func _apply_audio() -> void:
	_set_bus_volume("Master", _master_volume)
	_set_bus_volume("Music", _music_volume)
	_set_bus_volume("SFX", _sfx_volume)

static func _set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(linear_volume, 0.0001)) if linear_volume > 0.0 else -80.0)
	AudioServer.set_bus_mute(bus_index, linear_volume <= 0.0)

static func _apply_key_binding(action_name: String, physical_keycode: int) -> void:
	if not InputMap.has_action(action_name):
		return
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			InputMap.action_erase_event(action_name, event)
	var new_event: InputEventKey = InputEventKey.new()
	new_event.physical_keycode = physical_keycode
	InputMap.action_add_event(action_name, new_event)
