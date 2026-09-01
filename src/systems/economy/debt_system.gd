class_name DebtSystem
extends RefCounted
# owns: compounding debt and cash, and the tier read by other systems (dialogue, jobs) to
#   decide which options a given debt level closes off. per DESIGN.md, debt closes options,
#   it never ends a run: there is no game-over state anywhere in this file.
# does not own: what any given debt tier actually closes; that is a dialogue/content decision

## placeholder rate pending real economy balancing; easy to retune, never hardcoded elsewhere
const DAILY_INTEREST_RATE: float = 0.01
const TIER_THRESHOLDS: PackedFloat32Array = [0.0, 100.0, 400.0, 1000.0]

static func tick_day() -> void:
	if GameState.debt > 0.0:
		add_debt(GameState.debt * DAILY_INTEREST_RATE)

static func add_debt(amount: float) -> void:
	GameState.debt = maxf(0.0, GameState.debt + amount)
	EventBus.debt_changed.emit(GameState.debt)

static func pay_debt(amount: float) -> void:
	add_debt(-amount)

static func add_cash(amount: float) -> void:
	GameState.cash = maxf(0.0, GameState.cash + amount)
	EventBus.cash_changed.emit(GameState.cash)

static func spend_cash(amount: float) -> bool:
	if amount > GameState.cash:
		return false
	add_cash(-amount)
	return true

## 0 = no debt, higher tiers close more options. thresholds are placeholders, see the
## constant above, not a locked design number.
static func get_debt_tier() -> int:
	var tier: int = 0
	for i: int in range(TIER_THRESHOLDS.size()):
		if GameState.debt >= TIER_THRESHOLDS[i]:
			tier = i
	return tier
