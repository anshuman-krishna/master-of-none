class_name DialogueBoxController
extends Control
# owns: showing the right box (dialogue/thought/empty) for whatever node a DialogueRunner is
#   on, the character-by-character text reveal with punctuation pauses, and turning the
#   advance_dialogue input into either "reveal faster" or "go to the next node"
# does not own: node traversal or token resolution (see DialogueRunner, TokenResolver), the
#   document box (see F-017)

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
@onready var _option_labels: Array[BitmapLabel] = [
	$DialoguePanel/Option0, $DialoguePanel/Option1, $DialoguePanel/Option2, $DialoguePanel/Option3,
]
@onready var _document_panel: ColorRect = $DocumentPanel
@onready var _document_inner: ColorRect = $DocumentPanel/DocumentInner
@onready var _document_header_label: BitmapLabel = $DocumentPanel/DocumentInner/HeaderLabel
@onready var _document_body_label: BitmapLabel = $DocumentPanel/DocumentInner/BodyLabel

var _runner: DialogueRunner
var _active_label: BitmapLabel
var _full_text: String = ""
var _revealed_count: int = 0
var _reveal_timer: float = 0.0
var _is_mute_node: bool = false
var _choice_options: Array = []
var _selected_index: int = 0
var _in_choice: bool = false

func _ready() -> void:
	_dialogue_label.color = Palette.INK
	_thought_label.color = Palette.FROST
	_thought_label.italic = true
	_empty_name_label.color = Palette.INK
	_cursor.color = Palette.CONCRETE
	_document_panel.color = Palette.INK
	_document_inner.color = Palette.DOCUMENT
	_document_header_label.face_name = "institutional"
	_document_header_label.color = Palette.INK
	_document_body_label.face_name = "institutional"
	_document_body_label.color = Palette.INK
	_hide_all_panels()
	set_process(false)

func attach_runner(runner: DialogueRunner) -> void:
	_runner = runner
	_runner.node_shown.connect(_on_node_shown)
	_runner.choice_shown.connect(_on_choice_shown)

func _on_node_shown(node_data: Dictionary) -> void:
	match node_data.get("type", ""):
		"say":
			_show_text_node(_dialogue_panel, _dialogue_label, node_data.get("text", ""))
		"think":
			_show_text_node(_thought_panel, _thought_label, node_data.get("text", ""))
		"mute":
			_show_mute_node(node_data)
		"document":
			_show_document_node(node_data)
		_:
			_hide_all_panels()

## DialogueRunner emits choice nodes on their own signal rather than through node_shown.
func _on_choice_shown(options: Array) -> void:
	_show_choice_node(options)

func _show_text_node(panel: Control, label: BitmapLabel, text: String) -> void:
	_hide_all_panels()
	panel.visible = true
	_active_label = label
	_is_mute_node = false
	_full_text = text
	_revealed_count = 0
	label.visible_characters = 0
	_reveal_timer = _char_interval()
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
	_document_panel.visible = false
	_in_choice = false
	for label: BitmapLabel in _option_labels:
		label.visible = false

## documents (letters, forms, signs) render in mixed case, unlike spoken dialogue, and appear
## in full rather than typewriter-revealed: nobody reads a poster at 30 characters a second.
## there is no dedicated frame art for this yet (see testing/art-asset-inventory.md), so the
## frame is a plain ink-bordered document-colour panel until real art exists.
func _show_document_node(node_data: Dictionary) -> void:
	_hide_all_panels()
	_document_panel.visible = true
	_document_header_label.text = node_data.get("header", "")
	_document_header_label.visible_characters = -1
	_document_body_label.text = node_data.get("text", "")
	_document_body_label.visible_characters = -1
	_active_label = _document_body_label
	_full_text = node_data.get("text", "")
	_revealed_count = _full_text.length()
	_is_mute_node = false
	set_process(false)

## choice options render inside the dialogue panel, in place of the normal text line, since
## DIALOGUE_FORMAT.md treats the preceding dialogue as the prompt rather than giving choices
## their own frame. supports up to four options; a fifth would need a new panel, not a hack.
func _show_choice_node(options: Array) -> void:
	_hide_all_panels()
	_dialogue_panel.visible = true
	_active_label = null
	_is_mute_node = false
	set_process(false)
	_choice_options = options
	if _choice_options.size() > _option_labels.size():
		push_error("dialogue_box_controller: %d choice options exceeds the %d the ui supports" % [_choice_options.size(), _option_labels.size()])
	_selected_index = 0
	_in_choice = true
	_refresh_choice_display()

func _refresh_choice_display() -> void:
	for i: int in range(_option_labels.size()):
		var label: BitmapLabel = _option_labels[i]
		if i < _choice_options.size():
			var option: Dictionary = _choice_options[i]
			label.visible = true
			label.text = option.get("text", "")
			label.visible_characters = -1
			label.color = Palette.EMBER if i == _selected_index else Palette.INK
		else:
			label.visible = false

func _move_selection(step: int) -> void:
	if _choice_options.is_empty():
		return
	_selected_index = wrapi(_selected_index + step, 0, _choice_options.size())
	_refresh_choice_display()

func _confirm_choice() -> void:
	if _runner == null or _choice_options.is_empty():
		return
	var chosen_index: int = _selected_index
	_hide_all_panels()
	_runner.choose(chosen_index)

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
		return _char_interval() + COMMA_PAUSE
	if last_char == ".":
		return _char_interval() + PERIOD_PAUSE
	return _char_interval()

## the design floor is CHAR_INTERVAL (~30 chars/sec); settings can only speed this up, per
## SettingsSystem.get_text_speed_multiplier()'s own floor, never slow it below the authored pace
func _char_interval() -> float:
	return CHAR_INTERVAL / SettingsSystem.get_text_speed_multiplier()

## called on the advance_dialogue input. a choice confirms the highlighted option. the empty
## (mute) box holds itself and does not respond to input; the runner's own timer closes it.
## everything else: skip to full text on the first press, advance to the next node on the
## second.
func handle_advance_input() -> void:
	if _in_choice:
		_confirm_choice()
		return
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
	elif _in_choice and event.is_action_pressed("move_down"):
		_move_selection(1)
		get_viewport().set_input_as_handled()
	elif _in_choice and event.is_action_pressed("move_up"):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
