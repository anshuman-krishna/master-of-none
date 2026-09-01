class_name SettingsMenuController
extends Control
# owns: the settings menu (S-001): master/music/sfx volume, text speed, key rebinding, all
#   read from and written to SettingsSystem, which persists them to user://settings.json
# does not own: how settings are applied to the running game (see SettingsSystem.apply_all())

signal closed

const ROW_HEIGHT: int = 16
const START_Y: int = 10
const LABEL_X: int = 16
const VALUE_X: int = 200
const BAR_WIDTH: int = 100
const BAR_HEIGHT: int = 6
const VOLUME_STEP: float = 0.1
const TEXT_SPEED_STEP: float = 0.25

enum RowType { VOLUME, TEXT_SPEED, KEY_BIND }

var _rows: Array[Dictionary] = []
var _row_labels: Array[BitmapLabel] = []
var _row_value_labels: Array[BitmapLabel] = []
var _row_bars: Array[ColorRect] = []
var _selected_index: int = 0
var _capturing_action: String = ""

func _ready() -> void:
	_rows = [
		{"type": RowType.VOLUME, "name": "master volume", "getter": SettingsSystem.get_master_volume, "setter": SettingsSystem.set_master_volume},
		{"type": RowType.VOLUME, "name": "music volume", "getter": SettingsSystem.get_music_volume, "setter": SettingsSystem.set_music_volume},
		{"type": RowType.VOLUME, "name": "sfx volume", "getter": SettingsSystem.get_sfx_volume, "setter": SettingsSystem.set_sfx_volume},
		{"type": RowType.TEXT_SPEED, "name": "text speed"},
	]
	for action_name: String in SettingsSystem.REBINDABLE_ACTIONS:
		_rows.append({"type": RowType.KEY_BIND, "name": action_name})
	_build_rows()
	_refresh_display()

func _build_rows() -> void:
	for i: int in range(_rows.size()):
		var y: int = START_Y + i * ROW_HEIGHT
		var label: BitmapLabel = BitmapLabel.new()
		label.face_name = "institutional"
		label.position = Vector2(LABEL_X, y)
		label.text = _rows[i]["name"]
		label.visible_characters = -1
		add_child(label)
		_row_labels.append(label)

		var value_label: BitmapLabel = BitmapLabel.new()
		value_label.face_name = "institutional"
		value_label.position = Vector2(VALUE_X, y)
		value_label.visible_characters = -1
		add_child(value_label)
		_row_value_labels.append(value_label)

		if _rows[i]["type"] == RowType.VOLUME:
			var track: ColorRect = ColorRect.new()
			track.position = Vector2(VALUE_X, y)
			track.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
			track.color = Palette.STONE
			add_child(track)
			var fill: ColorRect = ColorRect.new()
			fill.position = Vector2(VALUE_X, y)
			fill.color = Palette.BRASS
			add_child(fill)
			_row_bars.append(fill)
		else:
			_row_bars.append(null)

func _refresh_display() -> void:
	for i: int in range(_rows.size()):
		var row: Dictionary = _rows[i]
		var is_selected: bool = i == _selected_index
		_row_labels[i].color = Palette.EMBER if is_selected else Palette.INK
		match row["type"]:
			RowType.VOLUME:
				var value: float = row["getter"].call()
				_row_value_labels[i].text = "%d%%" % roundi(value * 100.0)
				_row_value_labels[i].color = Palette.INK
				_row_bars[i].size = Vector2(BAR_WIDTH * value, BAR_HEIGHT)
			RowType.TEXT_SPEED:
				_row_value_labels[i].text = "%.2fx" % SettingsSystem.get_text_speed_multiplier()
				_row_value_labels[i].color = Palette.INK
			RowType.KEY_BIND:
				var action_name: String = row["name"]
				if _capturing_action == action_name:
					_row_value_labels[i].text = "press a key..."
					_row_value_labels[i].color = Palette.EMBER
				else:
					_row_value_labels[i].text = _current_key_label(action_name)
					_row_value_labels[i].color = Palette.INK

func _current_key_label(action_name: String) -> String:
	var bound_keycode: int = SettingsSystem.get_key_binding(action_name)
	if bound_keycode != -1:
		return OS.get_keycode_string(bound_keycode)
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			return OS.get_keycode_string((event as InputEventKey).physical_keycode)
	return "-"

func _move_selection(step: int) -> void:
	_selected_index = wrapi(_selected_index + step, 0, _rows.size())
	_refresh_display()

func _adjust_selected(step: int) -> void:
	var row: Dictionary = _rows[_selected_index]
	match row["type"]:
		RowType.VOLUME:
			row["setter"].call(row["getter"].call() + step * VOLUME_STEP)
		RowType.TEXT_SPEED:
			SettingsSystem.set_text_speed_multiplier(
				SettingsSystem.get_text_speed_multiplier() + step * TEXT_SPEED_STEP
			)
	_refresh_display()

func _confirm_selected() -> void:
	var row: Dictionary = _rows[_selected_index]
	if row["type"] == RowType.KEY_BIND:
		_capturing_action = row["name"]
		_refresh_display()

func _unhandled_input(event: InputEvent) -> void:
	if not _capturing_action.is_empty():
		if event is InputEventKey and event.pressed and not event.echo:
			SettingsSystem.rebind_key(_capturing_action, (event as InputEventKey).physical_keycode)
			_capturing_action = ""
			_refresh_display()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("move_down"):
		_move_selection(1)
	elif event.is_action_pressed("move_up"):
		_move_selection(-1)
	elif event.is_action_pressed("move_right"):
		_adjust_selected(1)
	elif event.is_action_pressed("move_left"):
		_adjust_selected(-1)
	elif event.is_action_pressed("advance_dialogue"):
		_confirm_selected()
	elif event.is_action_pressed("pause"):
		SettingsSystem.save()
		closed.emit()
	else:
		return
	get_viewport().set_input_as_handled()
