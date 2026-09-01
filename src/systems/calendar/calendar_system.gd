class_name CalendarSystem
extends RefCounted
# owns: the day tick, and calling the other day-based systems in the right order
# does not own: what happens on any given day narratively; that is scheduled events and
#   dialogue, not this file. scheduled_events is a day -> event id list for NPC
#   schedules and other date-locked content to hook into.

static var _scheduled_events: Dictionary = {}

static func advance_day() -> void:
	GameState.current_day += 1
	UpkeepSystem.tick_day()
	DebtSystem.tick_day()
	LetterSystem.deliver_scheduled(GameState.current_day)
	EventBus.day_advanced.emit(GameState.current_day)
	for event_id: String in get_events_for_day(GameState.current_day):
		EventRegistry.dispatch(event_id, {})

static func schedule_event(day: int, event_id: String) -> void:
	if not _scheduled_events.has(day):
		_scheduled_events[day] = []
	_scheduled_events[day].append(event_id)

static func get_events_for_day(day: int) -> Array:
	return _scheduled_events.get(day, [])
