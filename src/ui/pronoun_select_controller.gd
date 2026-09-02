class_name PronounSelectController
extends Control
# owns: the new-game boy/girl choice ("the player picks boy or girl before chapter 0"), which
#   sets GameState.pronoun before anything else can run
# does not own: what happens after the choice; see pronoun_chosen

signal pronoun_chosen(pronoun: GameState.Pronoun)

var _selected_index: int = 0
var _option_labels: Array[BitmapLabel] = []

@onready var _boy_label: BitmapLabel = $BoyOption
@onready var _girl_label: BitmapLabel = $GirlOption

func _ready() -> void:
	_boy_label.text = "boy"
	_girl_label.text = "girl"
	_boy_label.visible_characters = -1
	_girl_label.visible_characters = -1
	_option_labels = [_boy_label, _girl_label]
	_refresh_display()

func _refresh_display() -> void:
	for i: int in range(_option_labels.size()):
		_option_labels[i].color = Palette.EMBER if i == _selected_index else Palette.INK

func _move_selection(step: int) -> void:
	_selected_index = wrapi(_selected_index + step, 0, _option_labels.size())
	_refresh_display()

func _confirm_selection() -> void:
	var pronoun: GameState.Pronoun = GameState.Pronoun.BOY if _selected_index == 0 else GameState.Pronoun.GIRL
	GameState.set_pronoun(pronoun)
	pronoun_chosen.emit(pronoun)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_down"):
		_move_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_up"):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("advance_dialogue"):
		_confirm_selection()
		get_viewport().set_input_as_handled()
