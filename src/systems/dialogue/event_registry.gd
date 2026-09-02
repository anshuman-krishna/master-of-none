class_name EventRegistry
extends RefCounted
# owns: the mapping from a dialogue "event" node's event name to an actual game action
# does not own: the systems those actions call into (inventory, calendar, letters)

const REGISTERED_EVENTS: PackedStringArray = [
	"give_item",
	"advance_day",
	"start_cutscene",
	"trigger_letter",
	"increase_skill",
]

static func dispatch(event_name: String, args: Dictionary) -> void:
	if not REGISTERED_EVENTS.has(event_name):
		push_error("event_registry: unregistered event '%s'" % event_name)
		return
	match event_name:
		"give_item":
			_give_item(args)
		"advance_day":
			_advance_day(args)
		"start_cutscene":
			_start_cutscene(args)
		"trigger_letter":
			_trigger_letter(args)
		"increase_skill":
			_increase_skill(args)

static func _give_item(args: Dictionary) -> void:
	var item_id: String = args.get("item", "")
	if item_id.is_empty():
		push_error("event_registry: give_item called with no item id")
		return
	# the inventory system does not exist yet, so record the grant as a flag until it lands
	GameState.set_flag("has_item_%s" % item_id, true)

static func _advance_day(args: Dictionary) -> void:
	EventBus.day_advanced.emit(int(args.get("day", 0)))

static func _start_cutscene(args: Dictionary) -> void:
	push_warning("event_registry: start_cutscene is registered but has no implementation yet")

static func _trigger_letter(args: Dictionary) -> void:
	var letter_id: String = args.get("letter", "")
	if letter_id.is_empty():
		push_error("event_registry: trigger_letter called with no letter id")
		return
	EventBus.letter_received.emit(letter_id)

static func _increase_skill(args: Dictionary) -> void:
	var trade_id: String = args.get("trade", "")
	if trade_id.is_empty():
		push_error("event_registry: increase_skill called with no trade id")
		return
	SkillSystem.increase_level(trade_id, int(args.get("amount", 1)))
