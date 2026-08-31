class_name DialogueRunner
extends Node
# owns: loading a dialogue JSON file and walking its nodes in order
# does not own: how a node is drawn on screen, that belongs to the UI layer listening to these signals

signal node_shown(node_data: Dictionary)
signal choice_shown(options: Array)
signal dialogue_finished(dialogue_id: String)

var dialogue_id: String = ""

var _nodes_by_id: Dictionary = {}
var _current_node_id: String = ""
var _pronoun: int = 0
var _player_tokens: Dictionary = {}

func load_dialogue(path: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("dialogue_runner: could not open %s" % path)
		return false
	var raw_text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("dialogue_runner: %s did not parse to a dictionary" % path)
		return false
	var payload: Dictionary = parsed
	dialogue_id = payload.get("id", "")
	_nodes_by_id.clear()
	for node_data in payload.get("nodes", []):
		_nodes_by_id[node_data["id"]] = node_data
	return true

func start(pronoun: int, player_tokens: Dictionary, start_node_id: String = "") -> void:
	_pronoun = pronoun
	_player_tokens = player_tokens
	EventBus.dialogue_started.emit(dialogue_id)
	var first_id: String = start_node_id
	if first_id.is_empty() and not _nodes_by_id.is_empty():
		first_id = _nodes_by_id.keys()[0]
	_goto(first_id)

func advance() -> void:
	var node_data: Dictionary = _nodes_by_id.get(_current_node_id, {})
	_goto(node_data.get("next", ""))

func choose(option_index: int) -> void:
	var node_data: Dictionary = _nodes_by_id.get(_current_node_id, {})
	var options: Array = node_data.get("options", [])
	if option_index < 0 or option_index >= options.size():
		push_error("dialogue_runner: choice index %d out of range" % option_index)
		return
	_goto(options[option_index].get("next", ""))

func _goto(node_id: String) -> void:
	if node_id.is_empty() or not _nodes_by_id.has(node_id):
		_finish()
		return
	_current_node_id = node_id
	_process_node(_nodes_by_id[node_id])

func _process_node(node_data: Dictionary) -> void:
	match node_data.get("type", ""):
		"say", "think":
			var resolved: Dictionary = node_data.duplicate(true)
			resolved["text"] = TokenResolver.resolve(node_data.get("text", ""), _pronoun, _player_tokens, false)
			node_shown.emit(resolved)
		"mute":
			node_shown.emit(node_data)
			var hold_ms: int = node_data.get("hold_ms", 1000)
			await get_tree().create_timer(hold_ms / 1000.0).timeout
			advance()
		"document":
			var resolved: Dictionary = node_data.duplicate(true)
			resolved["text"] = TokenResolver.resolve(node_data.get("text", ""), _pronoun, _player_tokens, true)
			node_shown.emit(resolved)
		"choice":
			choice_shown.emit(node_data.get("options", []))
		"set":
			GameState.set_flag(node_data.get("flag", ""), node_data.get("value"))
			advance()
		"branch":
			var flag_value: Variant = GameState.get_flag(node_data.get("flag", ""), false)
			var next_id: String = node_data.get("if_true", "") if flag_value else node_data.get("if_false", "")
			_goto(next_id)
		"event":
			EventRegistry.dispatch(node_data.get("event", ""), node_data.get("args", {}))
			advance()
		"end":
			_finish()
		_:
			push_error("dialogue_runner: unknown node type '%s'" % node_data.get("type", ""))
			_finish()

func _finish() -> void:
	EventBus.dialogue_ended.emit(dialogue_id)
	dialogue_finished.emit(dialogue_id)
