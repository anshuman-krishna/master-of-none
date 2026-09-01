class_name FootstepBank
extends RefCounted
# owns: loading the surface id -> footstep clip list mapping from data/audio/footsteps.json
# does not own: when a footstep plays (see FootstepSystem)

const MANIFEST_PATH: String = "res://data/audio/footsteps.json"

static var _clips_by_surface: Dictionary = {}
static var _manifest: Dictionary = {}

static func get_random_clip(surface_id: String) -> AudioStream:
	_ensure_loaded()
	if not _manifest.has(surface_id):
		push_error("footstep_bank: unknown surface id '%s'" % surface_id)
		return null
	if not _clips_by_surface.has(surface_id):
		var loaded: Array = []
		for path: String in _manifest[surface_id]:
			loaded.append(load(path))
		_clips_by_surface[surface_id] = loaded
	var clips: Array = _clips_by_surface[surface_id]
	if clips.is_empty():
		return null
	return clips[randi() % clips.size()]

static func get_surface_ids() -> Array:
	_ensure_loaded()
	return _manifest.keys()

static func _ensure_loaded() -> void:
	if not _manifest.is_empty():
		return
	var file: FileAccess = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_error("footstep_bank: could not open %s" % MANIFEST_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_manifest = parsed
