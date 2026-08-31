class_name DialogueBoxController
extends Control
# owns: showing the right box (dialogue/thought/empty) for whatever node a DialogueRunner is
#   on, the character-by-character text reveal with punctuation pauses, and turning the
#   advance_dialogue input into either "reveal faster" or "go to the next node"
# does not own: node traversal or token resolution (see DialogueRunner, TokenResolver), the
#   document box (see F-017) or the choice list (see F-018)

const CHAR_INTERVAL: float = 1.0 / 30.0
const COMMA_PAUSE: float = 0.15
const PERIOD_PAUSE: float = 0.35
const ELLIPSIS_PAUSE: float = 0.6

@onready var _dialogue_panel: Control = $DialoguePanel
@onready var _dialogue_label: BitmapLabel = $DialoguePanel/TextLabel
@onready var _thought_panel: Control = $ThoughtPanel
@onready var _thought_label: BitmapLabel = $ThoughtPanel/TextLabel
@onready var _empty_panel: Control = $EmptyPanel
@onready var _empty_name_label: BitmapLabel = $EmptyPanel/NameLabel
@onready var _cursor: ColorRect = $EmptyPanel/Cursor

var _runner: DialogueRunner
var _active_label: BitmapLabel
var _full_text: String = ""
var _revealed_count: int = 0
var _reveal_timer: float = 0.0
var _is_mute_node: bool = false

func _ready() -> void:
	_dialogue_label.color = Palette.INK
	_thought_label.color = Palette.FROST
	_thought_label.italic = true
	_empty_name_label.color = Palette.INK
	_cursor.color = Palette.CONCRETE
	_hide_all_panels()
	set_process(false)

func attach_runner(runner: DialogueRunner) -> void:
	_runner = runner
	_runner.node_shown.connect(_on_node_shown)

func _on_node_shown(node_data: Dictionary) -> void:
	match node_data.get("type", ""):
		"say":
			_show_text_node(_dialogue_panel, _dialogue_label, node_data.get("text", ""))
		"think":
			_show_text_node(_thought_panel, _thought_label, node_data.get("text", ""))
		"mute":
			_show_mute_node(node_data)
		_:
			_hide_all_panels()

func _show_text_node(panel: Control, label: BitmapLabel, text: String) -> void:
	_hide_all_panels()
	panel.visible = true
	_active_label = label
	_is_mute_node = false
	_full_text = text
	_revealed_count = 0
	label.visible_characters = 0
	_reveal_timer = CHAR_INTERVAL
	set_process(true)

func _show_mute_node(node_data: Dictionary) -> void:
	_hide_all_panels()
	_empty_panel.visible = true
	_empty_name_label.text = node_data.get("speaker", "jack")
	_empty_name_label.visible_characters = -1
	_active_label = null
	_is_mute_node = true
	set_process(false)

func _hide_all_panels() -> void:
	_dialogue_panel.visible = false
	_thought_panel.visible = false
	_empty_panel.visible = false

func _process(delta: float) -> void:
	if _active_label == null or _revealed_count >= _full_text.length():
		set_process(false)
		return
	_reveal_timer -= delta
	if _reveal_timer > 0.0:
		return
	_revealed_count += 1
	_active_label.visible_characters = _revealed_count
	if _revealed_count < _full_text.length():
		_reveal_timer = _pause_after(_revealed_count)
	else:
		set_process(false)

func _pause_after(revealed_count: int) -> float:
	if revealed_count >= 3 and _full_text.substr(revealed_count - 3, 3) == "...":
		return ELLIPSIS_PAUSE
	var last_char: String = _full_text[revealed_count - 1]
	if last_char == ",":
		return CHAR_INTERVAL + COMMA_PAUSE
	if last_char == ".":
		return CHAR_INTERVAL + PERIOD_PAUSE
	return CHAR_INTERVAL

## called on the advance_dialogue input. the empty (mute) box holds itself and does not
## respond to input; the runner's own timer closes it. everything else: skip to full text on
## the first press, advance to the next node on the second.
func handle_advance_input() -> void:
	if _is_mute_node or _runner == null:
		return
	if _revealed_count < _full_text.length():
		_skip_reveal()
	else:
		_runner.advance()

func _skip_reveal() -> void:
	_revealed_count = _full_text.length()
	if _active_label != null:
		_active_label.visible_characters = _revealed_count
	set_process(false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("advance_dialogue"):
		handle_advance_input()
		get_viewport().set_input_as_handled()
