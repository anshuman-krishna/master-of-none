class_name SkillSystem
extends RefCounted
# owns: per-trade level 0-100 with a soft cap per DESIGN.md ("every skill sits at 70 to 85,
#   one bar, greyed out, reads mastery: requires certification")
# does not own: the stat screen's layout, or how a given job grants experience

const TRADES_PATH: String = "res://data/trades/trades.json"

static var _definitions: Dictionary = {}

static func get_trade_ids() -> Array:
	_ensure_loaded()
	return _definitions.keys()

static func get_display_name(trade_id: String) -> String:
	_ensure_loaded()
	return _definitions.get(trade_id, {}).get("display_name", trade_id)

static func get_cap(trade_id: String) -> int:
	_ensure_loaded()
	return int(_definitions.get(trade_id, {}).get("cap", 100))

static func get_level(trade_id: String) -> int:
	return int(GameState.skills.get(trade_id, 0))

## clamps at the trade's soft cap. going past it requires a formal apprenticeship, which is
## not a system this file builds, since jack has no papers.
static func increase_level(trade_id: String, amount: int) -> void:
	_ensure_loaded()
	if not _definitions.has(trade_id):
		push_error("skill_system: unknown trade id '%s'" % trade_id)
		return
	var new_level: int = clampi(get_level(trade_id) + amount, 0, get_cap(trade_id))
	GameState.skills[trade_id] = new_level
	EventBus.skill_changed.emit(trade_id, new_level)

static func is_at_cap(trade_id: String) -> bool:
	return get_level(trade_id) >= get_cap(trade_id)

static func _ensure_loaded() -> void:
	if not _definitions.is_empty():
		return
	var file: FileAccess = FileAccess.open(TRADES_PATH, FileAccess.READ)
	if file == null:
		push_error("skill_system: could not open %s" % TRADES_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_definitions = parsed
