class_name UpkeepSystem
extends RefCounted
# owns: hunger/hydration as modifiers (never a health bar), their daily decay, and the
#   zero-state collapse per DESIGN.md ("hitting zero does not kill you, you collapse, you
#   wake in a clinic, and eleven days later a letter arrives")
# does not own: what a collapse looks like on screen, or the clinic bill's contents

const HUNGER_DECAY_PER_DAY: float = 18.0
const HYDRATION_DECAY_PER_DAY: float = 24.0
const LOW_THRESHOLD: float = 30.0
const COLLAPSE_RECOVERY_VALUE: float = 45.0
const COLLAPSE_LETTER_DELAY_DAYS: int = 11
const COLLAPSE_LETTER_ID: String = "clinic_bill"

static func tick_day() -> void:
	restore_hunger(-HUNGER_DECAY_PER_DAY)
	restore_hydration(-HYDRATION_DECAY_PER_DAY)
	_check_collapse()

static func restore_hunger(amount: float) -> void:
	GameState.hunger = clampf(GameState.hunger + amount, 0.0, 100.0)
	EventBus.upkeep_changed.emit(GameState.hunger, GameState.hydration)

static func restore_hydration(amount: float) -> void:
	GameState.hydration = clampf(GameState.hydration + amount, 0.0, 100.0)
	EventBus.upkeep_changed.emit(GameState.hunger, GameState.hydration)

func is_collapsed() -> bool:
	return GameState.hunger <= 0.0 or GameState.hydration <= 0.0

## multiplies action speed. never zero: the game slows you down, it does not stop you.
static func get_action_speed_modifier() -> float:
	return _modifier_curve()

## multiplies skill check success odds.
static func get_skill_check_modifier() -> float:
	return _modifier_curve()

static func _modifier_curve() -> float:
	var lowest: float = minf(GameState.hunger, GameState.hydration)
	if lowest >= LOW_THRESHOLD:
		return 1.0
	return lerpf(0.5, 1.0, lowest / LOW_THRESHOLD)

static func _check_collapse() -> void:
	if GameState.hunger > 0.0 and GameState.hydration > 0.0:
		return
	GameState.hunger = COLLAPSE_RECOVERY_VALUE
	GameState.hydration = COLLAPSE_RECOVERY_VALUE
	EventBus.upkeep_changed.emit(GameState.hunger, GameState.hydration)
	EventBus.player_collapsed.emit()
	LetterSystem.schedule_letter(COLLAPSE_LETTER_ID, GameState.current_day + COLLAPSE_LETTER_DELAY_DAYS)
