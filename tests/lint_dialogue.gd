extends SceneTree
# owns: static validation of every file in data/dialogue/ against docs/DIALOGUE_FORMAT.md
# does not own: rendering dialogue or resolving tokens at runtime (see DialogueRunner, TokenResolver)
#
# run with: godot --headless --script tests/lint_dialogue.gd --path .

const DIALOGUE_ROOT: String = "res://data/dialogue"
const NPC_ROOT: String = "res://data/npcs"

# duplicated from EventRegistry.REGISTERED_EVENTS rather than loaded from it: that script
# touches the GameState and EventBus autoloads in its dispatch functions, which are not
# initialised when this file runs standalone via `godot --script`. keep this list in sync
# with src/systems/dialogue/event_registry.gd by hand.
const REGISTERED_EVENTS: PackedStringArray = [
	"give_item",
	"advance_day",
	"start_cutscene",
	"trigger_letter",
]

var _error_count: int = 0

func _init() -> void:
	var files: Array[String] = _collect_json_files(DIALOGUE_ROOT)
	if files.is_empty():
		print("lint_dialogue: no dialogue files found under %s" % DIALOGUE_ROOT)
	var known_npcs: Dictionary = _load_known_npcs()
	for path in files:
		_lint_file(path, known_npcs)
	if _error_count > 0:
		printerr("lint_dialogue: %d error(s) found" % _error_count)
		quit(1)
	else:
		print("lint_dialogue: all clear (%d file(s) checked)" % files.size())
		quit(0)

func _collect_json_files(root: String) -> Array[String]:
	var results: Array[String] = []
	if DirAccess.open(root) == null:
		return results
	_walk(root, results)
	return results

func _walk(path: String, results: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = dir.get_next()
			continue
		var full_path: String = path.path_join(entry)
		if dir.current_is_dir():
			_walk(full_path, results)
		elif entry.ends_with(".json"):
			results.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()

func _load_known_npcs() -> Dictionary:
	var npcs: Dictionary = {}
	for path in _collect_json_files(NPC_ROOT):
		var data: Variant = _read_json(path)
		if typeof(data) == TYPE_DICTIONARY and data.has("id"):
			npcs[data["id"]] = data.get("portraits", [])
	return npcs

func _read_json(path: String) -> Variant:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var raw_text: String = file.get_as_text()
	file.close()
	return JSON.parse_string(raw_text)

func _lint_file(path: String, known_npcs: Dictionary) -> void:
	var data: Variant = _read_json(path)
	if typeof(data) != TYPE_DICTIONARY:
		_fail(path, "did not parse to a dictionary")
		return
	var payload: Dictionary = data
	var nodes: Array = payload.get("nodes", [])
	if nodes.is_empty():
		_fail(path, "has no nodes")
		return

	var nodes_by_id: Dictionary = {}
	for node_data in nodes:
		if typeof(node_data) != TYPE_DICTIONARY or not node_data.has("id"):
			_fail(path, "found a node with no id")
			continue
		nodes_by_id[node_data["id"]] = node_data

	var reachable: Dictionary = {}
	reachable[nodes[0]["id"]] = true

	for node_data in nodes:
		_lint_node(path, node_data, nodes_by_id, known_npcs, reachable)

	for node_id: String in nodes_by_id.keys():
		if not reachable.has(node_id):
			_fail(path, "node '%s' is unreachable" % node_id)

func _lint_node(path: String, node_data: Dictionary, nodes_by_id: Dictionary, known_npcs: Dictionary, reachable: Dictionary) -> void:
	var node_type: String = node_data.get("type", "")
	var node_id: String = node_data.get("id", "?")

	match node_type:
		"say", "think":
			_check_text(path, node_id, node_data.get("text", ""), false)
			if node_type == "say" and node_data.has("speaker"):
				_check_speaker(path, node_id, node_data, known_npcs)
			if node_type == "think" or (node_type == "say" and node_data.get("speaker", "") == "jack"):
				_check_hardcoded_pronoun(path, node_id, node_data.get("text", ""))
			_mark_next(path, node_id, node_data, nodes_by_id, reachable)
		"mute":
			if node_data.has("speaker"):
				_check_speaker(path, node_id, node_data, known_npcs)
			_mark_next(path, node_id, node_data, nodes_by_id, reachable)
		"document":
			_check_text(path, node_id, node_data.get("text", ""), true)
			_mark_next(path, node_id, node_data, nodes_by_id, reachable)
		"choice":
			for option: Variant in node_data.get("options", []):
				if typeof(option) == TYPE_DICTIONARY and option.has("next"):
					reachable[option["next"]] = true
					if not nodes_by_id.has(option["next"]):
						_fail(path, "choice at '%s' points to missing node '%s'" % [node_id, option["next"]])
		"set":
			_mark_next(path, node_id, node_data, nodes_by_id, reachable)
		"branch":
			for branch_key: String in ["if_true", "if_false"]:
				if node_data.has(branch_key):
					var target: String = node_data[branch_key]
					reachable[target] = true
					if not nodes_by_id.has(target):
						_fail(path, "branch at '%s' points to missing node '%s'" % [node_id, target])
		"event":
			var event_name: String = node_data.get("event", "")
			if not REGISTERED_EVENTS.has(event_name):
				_fail(path, "node '%s' uses unregistered event '%s'" % [node_id, event_name])
			_mark_next(path, node_id, node_data, nodes_by_id, reachable)
		"end":
			pass
		_:
			_fail(path, "node '%s' has unknown type '%s'" % [node_id, node_type])

	var text: Variant = node_data.get("text", "")
	if typeof(text) == TYPE_STRING and text.find("{full_name}") != -1:
		if node_data.get("note", "") != "only full name line":
			_fail(path, "node '%s' uses {full_name} without the 'only full name line' note" % node_id)

func _mark_next(path: String, node_id: String, node_data: Dictionary, nodes_by_id: Dictionary, reachable: Dictionary) -> void:
	if node_data.has("next") and node_data["next"] != null:
		var target: String = node_data["next"]
		reachable[target] = true
		if not nodes_by_id.has(target):
			_fail(path, "node '%s' points to missing node '%s'" % [node_id, target])

func _check_text(path: String, node_id: String, text: String, allow_capitals: bool) -> void:
	if not allow_capitals:
		for character: String in text:
			if character != character.to_lower():
				_fail(path, "node '%s' has a capital letter in lowercase-only text" % node_id)
				break
	if text.find("—") != -1:
		_fail(path, "node '%s' contains an em dash" % node_id)
	if text.length() > 120:
		_fail(path, "node '%s' text is over 120 characters" % node_id)

func _check_speaker(path: String, node_id: String, node_data: Dictionary, known_npcs: Dictionary) -> void:
	var speaker: String = node_data.get("speaker", "")
	if speaker.is_empty():
		return
	if not known_npcs.has(speaker):
		_fail(path, "node '%s' uses unknown speaker '%s'" % [node_id, speaker])
		return
	var portrait: String = node_data.get("portrait", "")
	if not portrait.is_empty():
		var known_portraits: Array = known_npcs[speaker]
		if not known_portraits.has(portrait):
			_fail(path, "node '%s' uses unknown portrait '%s' for speaker '%s'" % [node_id, portrait, speaker])

## checks for a hardcoded gendered pronoun outside a token, scoped to text that speaks for or
## as jack: think nodes are always his interior voice, and say nodes where speaker is "jack".
## other characters keep their own pronouns hardcoded on purpose, since only jack's pronoun
## depends on the player's choice at character creation.
func _check_hardcoded_pronoun(path: String, node_id: String, text: String) -> void:
	var regex: RegEx = RegEx.new()
	regex.compile("(?i)\\b(he|him|his|himself|she|her|hers|herself)\\b")
	var found: RegExMatch = regex.search(text)
	if found:
		_fail(path, "node '%s' hardcodes a gendered pronoun ('%s') instead of using a token" % [node_id, found.get_string()])

func _fail(path: String, message: String) -> void:
	_error_count += 1
	printerr("%s: %s" % [path, message])
