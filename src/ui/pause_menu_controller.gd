class_name PauseMenuController
extends CanvasLayer
# owns: the pause overlay reachable from gameplay via the "pause" action: resume, open
#   settings, or quit. this is what actually makes SettingsMenuController reachable in game,
#   since nothing else in the project opens it yet.
# does not own: the settings themselves (see SettingsSystem), or a main-menu/title flow, which
#   does not exist yet, so "quit" exits the application rather than returning to one

signal resumed

const ROW_NAMES: Array[String] = ["resume", "settings", "quit"]
const ROW_HEIGHT: int = 16
const START_Y: int = 100
const LABEL_X: int = 200

var _selected_index: int = 0
var _row_labels: Array[BitmapLabel] = []
var _settings_menu: Control
var _paused: bool = false

@onready var _cover: ColorRect = $Cover
@onready var _rows_container: Control = $Rows

func _ready() -> void:
	layer = 90
	_cover.color = Palette.NIGHT
	_cover.color.a = 0.7
	for i: int in range(ROW_NAMES.size()):
		var label: BitmapLabel = BitmapLabel.new()
		label.face_name = "institutional"
		label.position = Vector2(LABEL_X, START_Y + i * ROW_HEIGHT)
		label.text = ROW_NAMES[i]
		label.visible_characters = -1
		_rows_container.add_child(label)
		_row_labels.append(label)
	set_paused_visible(false)

func set_paused_visible(value: bool) -> void:
	_paused = value
	visible = value
	_selected_index = 0
	get_tree().paused = value
	process_mode = Node.PROCESS_MODE_ALWAYS
	if value:
		_refresh_display()

func _refresh_display() -> void:
	for i: int in range(_row_labels.size()):
		_row_labels[i].color = Palette.EMBER if i == _selected_index else Palette.FROST

func _unhandled_input(event: InputEvent) -> void:
	if _settings_menu != null:
		return
	if not _paused:
		if event.is_action_pressed("pause"):
			set_paused_visible(true)
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("move_down"):
		_selected_index = wrapi(_selected_index + 1, 0, ROW_NAMES.size())
		_refresh_display()
	elif event.is_action_pressed("move_up"):
		_selected_index = wrapi(_selected_index - 1, 0, ROW_NAMES.size())
		_refresh_display()
	elif event.is_action_pressed("advance_dialogue"):
		_confirm_selected()
	elif event.is_action_pressed("pause"):
		_resume()
	else:
		return
	get_viewport().set_input_as_handled()

func _confirm_selected() -> void:
	match ROW_NAMES[_selected_index]:
		"resume":
			_resume()
		"settings":
			_open_settings()
		"quit":
			get_tree().quit()

func _resume() -> void:
	set_paused_visible(false)
	resumed.emit()

func _open_settings() -> void:
	var scene: PackedScene = load("res://src/scenes/shared/settings_menu.tscn")
	_settings_menu = scene.instantiate()
	_settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_settings_menu)
	_settings_menu.closed.connect(_on_settings_closed)

func _on_settings_closed() -> void:
	_settings_menu.queue_free()
	_settings_menu = null
	_refresh_display()
