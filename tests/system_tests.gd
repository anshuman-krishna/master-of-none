extends Node
# owns: a permanent, rerunnable regression suite for the static-dispatch gameplay systems and
#   the two autoloads that persist state (SaveManager, GameState). replaces the disposable
#   boot.gd swaps this project used before to hand-verify the same behaviour by hand each time.
# does not own: dialogue content validation (see tests/lint_dialogue.gd), or any visual/pixel
#   check, since headless mode cannot produce a real frame to inspect
#
# run with: godot --headless --path . res://tests/system_tests.tscn
#
# touches the real user:// save and settings files while it runs, since GameState, SaveManager
# and SettingsSystem have no test-only path to write to. backs both up before running and
# restores them afterwards, deleting them again if they did not exist beforehand.

var _pass_count: int = 0
var _fail_count: int = 0

func _ready() -> void:
	_reset_game_state()
	var backups: Dictionary = _backup_user_files()

	_test_token_resolver()
	_test_player_tokens()
	_test_save_manager()
	_test_upkeep_system()
	_test_debt_system()
	_test_skill_system()
	_test_letter_system()
	_test_calendar_system()
	_test_map_system()
	_test_settings_system()
	_test_event_registry()

	_restore_user_files(backups)

	if _fail_count > 0:
		printerr("system_tests: %d failed, %d passed" % [_fail_count, _pass_count])
		get_tree().quit(1)
	else:
		print("system_tests: all clear (%d checks)" % _pass_count)
		get_tree().quit(0)

func _check(check_name: String, condition: bool) -> void:
	if condition:
		_pass_count += 1
	else:
		_fail_count += 1
		printerr("FAIL: %s" % check_name)

func _reset_game_state() -> void:
	GameState.current_chapter = 0
	GameState.pronoun = 0
	GameState.flags = {}
	GameState.player_tokens = {}
	GameState.current_day = 0
	GameState.hunger = 100.0
	GameState.hydration = 100.0
	GameState.debt = 0.0
	GameState.cash = 0.0
	GameState.skills = {}
	GameState.letters = []
	GameState.scheduled_letters = []
	GameState.map_stage = 0

func _backup_user_files() -> Dictionary:
	var backups: Dictionary = {}
	for path: String in [SaveManager.SAVE_PATH, SettingsSystem.SETTINGS_PATH]:
		if FileAccess.file_exists(path):
			var file: FileAccess = FileAccess.open(path, FileAccess.READ)
			backups[path] = file.get_as_text()
			file.close()
	return backups

func _restore_user_files(backups: Dictionary) -> void:
	for path: String in [SaveManager.SAVE_PATH, SettingsSystem.SETTINGS_PATH]:
		if backups.has(path):
			var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
			file.store_string(backups[path])
			file.close()
		elif FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _test_token_resolver() -> void:
	_check("token resolver: boy pronoun set",
		TokenResolver.resolve("{they} said {theirs}.", 0) == "he said his.")
	_check("token resolver: girl pronoun set",
		TokenResolver.resolve("{they} said {theirs}.", 1) == "she said hers.")
	_check("token resolver: player token substitution",
		TokenResolver.resolve("hello {kitten_1}", 0, {"kitten_1": "ash"}) == "hello ash")
	_check("token resolver: text with no tokens is untouched",
		TokenResolver.resolve("no tokens here", 0) == "no tokens here")
	_check("token resolver: unknown token is left in place",
		TokenResolver.resolve("has {missing_token} in it", 0) == "has {missing_token} in it")
	_check("token resolver: full_name lowercase outside document context",
		TokenResolver.resolve("{full_name} is here.", 0, {}, false) == "jacob is here.")
	_check("token resolver: full_name capitalises at the start of a document",
		TokenResolver.resolve("{full_name} is here.", 0, {}, true) == "Jacob is here.")

func _test_player_tokens() -> void:
	_check("game state: player token trims whitespace",
		GameState.set_player_token("kitten_1", "  ash  ") and GameState.get_player_token("kitten_1") == "ash")
	_check("game state: whitespace-only token is rejected",
		not GameState.set_player_token("kitten_2", "   "))
	var long_input: String = "x".repeat(30)
	GameState.set_player_token("kitten_3", long_input)
	_check("game state: player token caps at 16 characters",
		GameState.get_player_token("kitten_3").length() == GameState.MAX_TOKEN_LENGTH)
	GameState.set_player_token("kitten_1", "a" + char(0x01) + "b" + char(0x7f) + "c")
	_check("game state: control characters are stripped",
		GameState.get_player_token("kitten_1") == "abc")

func _test_save_manager() -> void:
	GameState.current_chapter = 2
	GameState.set_flag("met_fen", true)
	GameState.cash = 40.0
	var saved: bool = SaveManager.save_game()
	_check("save manager: save_game reports success", saved)

	GameState.current_chapter = 0
	GameState.flags = {}
	GameState.cash = 0.0

	var loaded: bool = SaveManager.load_game()
	_check("save manager: load_game reports success", loaded)
	_check("save manager: chapter round trips", GameState.current_chapter == 2)
	_check("save manager: flag round trips", GameState.get_flag("met_fen") == true)
	_check("save manager: cash round trips", is_equal_approx(GameState.cash, 40.0))

func _test_upkeep_system() -> void:
	GameState.hunger = 100.0
	GameState.hydration = 100.0
	UpkeepSystem.tick_day()
	_check("upkeep: hunger decays on a day tick",
		is_equal_approx(GameState.hunger, 100.0 - UpkeepSystem.HUNGER_DECAY_PER_DAY))
	_check("upkeep: hydration decays on a day tick",
		is_equal_approx(GameState.hydration, 100.0 - UpkeepSystem.HYDRATION_DECAY_PER_DAY))
	_check("upkeep: no modifier penalty while above the low threshold",
		is_equal_approx(UpkeepSystem.get_action_speed_modifier(), 1.0))

	var collapsed: Array = [false]
	EventBus.player_collapsed.connect(func() -> void: collapsed[0] = true)
	GameState.current_day = 9
	GameState.hunger = 0.0
	GameState.hydration = 50.0
	UpkeepSystem.tick_day()
	_check("upkeep: zero hunger triggers collapse recovery, not death",
		is_equal_approx(GameState.hunger, UpkeepSystem.COLLAPSE_RECOVERY_VALUE)
		and is_equal_approx(GameState.hydration, UpkeepSystem.COLLAPSE_RECOVERY_VALUE))
	_check("upkeep: collapse fires player_collapsed", collapsed[0])
	var found_clinic_bill: bool = false
	for scheduled: Dictionary in GameState.scheduled_letters:
		if scheduled.get("id", "") == UpkeepSystem.COLLAPSE_LETTER_ID \
				and int(scheduled.get("arrival_day", -1)) == 9 + UpkeepSystem.COLLAPSE_LETTER_DELAY_DAYS:
			found_clinic_bill = true
	_check("upkeep: collapse schedules the clinic bill eleven days out", found_clinic_bill)

func _test_debt_system() -> void:
	GameState.debt = 0.0
	DebtSystem.add_debt(100.0)
	_check("debt: add_debt increases debt", is_equal_approx(GameState.debt, 100.0))
	_check("debt: tier reflects the 100 threshold", DebtSystem.get_debt_tier() == 1)
	DebtSystem.pay_debt(1000.0)
	_check("debt: debt never goes negative", is_equal_approx(GameState.debt, 0.0))

	GameState.debt = 100.0
	DebtSystem.tick_day()
	_check("debt: compounds by the daily interest rate on a tick",
		is_equal_approx(GameState.debt, 101.0))

	GameState.cash = 0.0
	DebtSystem.add_cash(50.0)
	_check("debt: spend_cash succeeds within balance",
		DebtSystem.spend_cash(30.0) and is_equal_approx(GameState.cash, 20.0))
	_check("debt: spend_cash refuses to overdraw",
		not DebtSystem.spend_cash(1000.0) and is_equal_approx(GameState.cash, 20.0))

func _test_skill_system() -> void:
	GameState.skills = {}
	SkillSystem.increase_level("carpentry", 200)
	_check("skills: level clamps at the trade's soft cap",
		SkillSystem.get_level("carpentry") == SkillSystem.get_cap("carpentry"))
	_check("skills: is_at_cap reports true at the cap", SkillSystem.is_at_cap("carpentry"))
	_check("skills: display name resolves from the data file",
		SkillSystem.get_display_name("carpentry") == "carpentry")
	SkillSystem.increase_level("not_a_real_trade", 10)
	_check("skills: an unknown trade id is not silently recorded",
		not GameState.skills.has("not_a_real_trade"))

func _test_letter_system() -> void:
	GameState.letters = []
	GameState.scheduled_letters = []
	GameState.current_day = 0
	LetterSystem.receive_letter("tax")
	_check("letters: receiving a letter adds it unopened", LetterSystem.get_unopened_count() == 1)
	LetterSystem.open_letter("tax")
	_check("letters: opening a letter clears the unopened count", LetterSystem.get_unopened_count() == 0)

	LetterSystem.schedule_letter("water", 3)
	LetterSystem.deliver_scheduled(0)
	_check("letters: a scheduled letter does not arrive early",
		LetterSystem.get_stack().size() == 1)
	LetterSystem.deliver_scheduled(3)
	_check("letters: a scheduled letter arrives on its day",
		LetterSystem.get_stack().size() == 2 and GameState.scheduled_letters.is_empty())

func _test_calendar_system() -> void:
	GameState.current_day = 0
	GameState.hunger = 100.0
	GameState.hydration = 100.0
	GameState.debt = 0.0
	CalendarSystem.advance_day()
	_check("calendar: advancing a day increments the day counter", GameState.current_day == 1)
	_check("calendar: advancing a day runs the upkeep tick",
		is_equal_approx(GameState.hunger, 100.0 - UpkeepSystem.HUNGER_DECAY_PER_DAY))

	CalendarSystem.schedule_event(7, "some_future_beat")
	_check("calendar: a scheduled event is returned on its day",
		CalendarSystem.get_events_for_day(7).has("some_future_beat"))
	_check("calendar: no events on a day nothing was scheduled for",
		CalendarSystem.get_events_for_day(3).is_empty())

func _test_map_system() -> void:
	GameState.current_chapter = 0
	_check("map: home corner refuses before chapter 5", not MapSystem.try_open_home_corner())
	GameState.current_chapter = 5
	_check("map: home corner opens at chapter 5", MapSystem.try_open_home_corner())

	GameState.map_stage = 0
	for _i in range(5):
		MapSystem.advance_stage()
	_check("map: stage clamps at MAX_STAGE", GameState.map_stage == MapSystem.MAX_STAGE)

func _test_settings_system() -> void:
	SettingsSystem.set_master_volume(0.5)
	_check("settings: master volume stores the requested value",
		is_equal_approx(SettingsSystem.get_master_volume(), 0.5))
	SettingsSystem.set_master_volume(-1.0)
	_check("settings: volume clamps at zero", is_equal_approx(SettingsSystem.get_master_volume(), 0.0))
	var master_bus: int = AudioServer.get_bus_index("Master")
	_check("settings: zero volume mutes the bus", master_bus != -1 and AudioServer.is_bus_mute(master_bus))
	SettingsSystem.set_master_volume(2.0)
	_check("settings: volume clamps at one", is_equal_approx(SettingsSystem.get_master_volume(), 1.0))

	SettingsSystem.set_text_speed_multiplier(0.1)
	_check("settings: text speed never drops below the design floor",
		is_equal_approx(SettingsSystem.get_text_speed_multiplier(), SettingsSystem.MIN_TEXT_SPEED_MULTIPLIER))
	SettingsSystem.set_text_speed_multiplier(10.0)
	_check("settings: text speed clamps at the ceiling",
		is_equal_approx(SettingsSystem.get_text_speed_multiplier(), SettingsSystem.MAX_TEXT_SPEED_MULTIPLIER))

	SettingsSystem.rebind_key("interact", KEY_F)
	_check("settings: rebind_key stores the new binding", SettingsSystem.get_key_binding("interact") == KEY_F)
	var found_binding: bool = false
	for event: InputEvent in InputMap.action_get_events("interact"):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_F:
			found_binding = true
	_check("settings: rebind_key updates the live InputMap", found_binding)
	SettingsSystem.rebind_key("not_a_real_action", KEY_G)
	_check("settings: rebinding an unlisted action is refused",
		SettingsSystem.get_key_binding("not_a_real_action") == -1)

	SettingsSystem.save()
	_check("settings: save writes the settings file", FileAccess.file_exists(SettingsSystem.SETTINGS_PATH))

func _test_event_registry() -> void:
	GameState.flags = {}
	EventRegistry.dispatch("give_item", {"item": "map"})
	_check("event registry: give_item sets the expected flag", GameState.get_flag("has_item_map") == true)

	var received_letter: Array = [""]
	EventBus.letter_received.connect(func(letter_id: String) -> void: received_letter[0] = letter_id)
	EventRegistry.dispatch("trigger_letter", {"letter": "tax"})
	_check("event registry: trigger_letter fires letter_received", received_letter[0] == "tax")

	var advanced_to: Array = [-1]
	EventBus.day_advanced.connect(func(day: int) -> void: advanced_to[0] = day)
	EventRegistry.dispatch("advance_day", {"day": 5})
	_check("event registry: advance_day fires day_advanced with its argument", advanced_to[0] == 5)

	EventRegistry.dispatch("not_a_registered_event", {})
	_check("event registry: an unregistered event does not crash the dispatcher", true)
