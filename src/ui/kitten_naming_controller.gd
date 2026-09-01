class_name KittenNamingController
extends Control
# owns: C1-002, the grave-side naming input where the player types the three kitten names
#   later resolved through {kitten_1..3} tokens (see GameState.set_player_token,
#   GameState.KITTEN_TOKEN_KEYS, docs/DIALOGUE_FORMAT.md)
# does not own: the grave scene itself or its dialogue, which does not exist yet (C1-001)

signal naming_finished

const ROW_HEIGHT: int = 20
const START_Y: int = 60
const LABEL_X: int = 40
const TYPING_CAP: int = 24
const CURSOR_BLINK_INTERVAL: float = 0.5

var _entries: Array[String] = ["", "", ""]
var _active_index: int = 0
var _cursor_visible: bool = true
var _cursor_timer: float = 0.0
var _row_labels: Array[BitmapLabel] = []

func _ready() -> void:
	for i: int in range(GameState.KITTEN_TOKEN_KEYS.size()):
		var label: BitmapLabel = BitmapLabel.new()
		# "handwriting" is not a separate alphabet (see assets/fonts/fonts.json): it is the
		# dialogue face plus wobble_amplitude and the pencil colour (palette walnut, 03)
		label.face_name = "dialogue"
		label.wobble_amplitude = 1
		label.color = Palette.WALNUT
		label.position = Vector2(LABEL_X, START_Y + i * ROW_HEIGHT)
		label.visible_characters = -1
		add_child(label)
		_row_labels.append(label)
	_refresh_display()

func _process(delta: float) -> void:
	_cursor_timer += delta
	if _cursor_timer >= CURSOR_BLINK_INTERVAL:
		_cursor_timer = 0.0
		_cursor_visible = not _cursor_visible
		_refresh_display()

func _refresh_display() -> void:
	for i: int in range(_row_labels.size()):
		var text: String = _entries[i]
		if i == _active_index and _cursor_visible:
			text += "_"
		_row_labels[i].text = text
		_row_labels[i].color = Palette.EMBER if i == _active_index else Palette.WALNUT

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	var key_event: InputEventKey = event as InputEventKey
	if key_event.physical_keycode == KEY_BACKSPACE:
		if not _entries[_active_index].is_empty():
			_entries[_active_index] = _entries[_active_index].substr(0, _entries[_active_index].length() - 1)
			_refresh_display()
		get_viewport().set_input_as_handled()
	elif key_event.physical_keycode == KEY_ENTER or key_event.physical_keycode == KEY_KP_ENTER:
		_confirm_current()
		get_viewport().set_input_as_handled()
	elif key_event.unicode > 0 and _entries[_active_index].length() < TYPING_CAP:
		# the dialogue face is lowercase only by design (fonts.json); token render
		# context adds capitals where a sentence needs one, same rule as {full_name}
		_entries[_active_index] += char(key_event.unicode).to_lower()
		_refresh_display()
		get_viewport().set_input_as_handled()

func _confirm_current() -> void:
	if _entries[_active_index].strip_edges().is_empty():
		return
	if _active_index < _entries.size() - 1:
		_active_index += 1
		_refresh_display()
	else:
		_finish()

func _finish() -> void:
	for i: int in range(GameState.KITTEN_TOKEN_KEYS.size()):
		GameState.set_player_token(GameState.KITTEN_TOKEN_KEYS[i], _entries[i])
	naming_finished.emit()
