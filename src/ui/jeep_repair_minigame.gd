class_name JeepRepairMinigame
extends Control
# owns: the two-step interactive fix docs/STORY.md 3.3 describes: scraping the corroded
#   contacts with a coin edge, then twisting the loose wire back onto the motor terminal.
#   driven by repeated `interact` presses rather than narrated through dialogue.
# does not own: the dialogue before or after it (see c0_jeep_repair_intro/outro.json), or what
#   happens on completion (the caller connects to `repair_complete`)

signal repair_complete

const SCRAPE_PRESSES_REQUIRED: int = 4

enum Step { SCRAPE, TWIST }

@onready var _prompt_label: BitmapLabel = $PromptLabel

var _step: Step = Step.SCRAPE
var _scrape_count: int = 0

func _ready() -> void:
	_prompt_label.face_name = "dialogue"
	_prompt_label.color = Palette.FROST
	_refresh_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	match _step:
		Step.SCRAPE:
			_scrape_count += 1
			if _scrape_count >= SCRAPE_PRESSES_REQUIRED:
				_step = Step.TWIST
			_refresh_prompt()
		Step.TWIST:
			repair_complete.emit()

func _refresh_prompt() -> void:
	match _step:
		Step.SCRAPE:
			_prompt_label.text = "scrape the contacts: " + str(_scrape_count) + " of " + str(SCRAPE_PRESSES_REQUIRED)
		Step.TWIST:
			_prompt_label.text = "twist the wire onto the post"
	_prompt_label.visible_characters = -1
