class_name LetterSystem
extends RefCounted
# owns: letters arriving through the slot, the visible stack, opened/unopened state, and
#   letters scheduled to arrive on a future day (see the upkeep collapse -> clinic bill link)
# does not own: the physical table/stack visual, or what a letter's contents actually say

const LETTERS_PATH: String = "res://data/letters/letters.json"

static var _definitions: Dictionary = {}

static func get_definition(letter_id: String) -> Dictionary:
	_ensure_loaded()
	return _definitions.get(letter_id, {})

static func receive_letter(letter_id: String) -> void:
	_ensure_loaded()
	if not _definitions.has(letter_id):
		push_error("letter_system: unknown letter id '%s'" % letter_id)
		return
	GameState.letters.append({
		"id": letter_id,
		"arrived_day": GameState.current_day,
		"opened": false,
	})
	EventBus.letter_received.emit(letter_id)

static func open_letter(letter_id: String) -> void:
	for letter: Dictionary in GameState.letters:
		if letter.get("id", "") == letter_id and not letter.get("opened", false):
			letter["opened"] = true
			EventBus.letter_opened.emit(letter_id)
			return

## queues a letter to arrive on a future day rather than immediately. used for things like
## the clinic bill that follows an upkeep collapse eleven days later.
static func schedule_letter(letter_id: String, arrival_day: int) -> void:
	GameState.scheduled_letters.append({"id": letter_id, "arrival_day": arrival_day})

## call once per day advance, after GameState.current_day has been updated, to deliver
## anything whose arrival day has come.
static func deliver_scheduled(current_day: int) -> void:
	var remaining: Array = []
	for scheduled: Dictionary in GameState.scheduled_letters:
		if int(scheduled.get("arrival_day", 0)) <= current_day:
			receive_letter(scheduled.get("id", ""))
		else:
			remaining.append(scheduled)
	GameState.scheduled_letters = remaining

static func get_unopened_count() -> int:
	var count: int = 0
	for letter: Dictionary in GameState.letters:
		if not letter.get("opened", false):
			count += 1
	return count

static func get_stack() -> Array:
	return GameState.letters

static func _ensure_loaded() -> void:
	if not _definitions.is_empty():
		return
	var file: FileAccess = FileAccess.open(LETTERS_PATH, FileAccess.READ)
	if file == null:
		push_error("letter_system: could not open %s" % LETTERS_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_definitions = parsed
