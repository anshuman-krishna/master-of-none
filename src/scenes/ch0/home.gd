extends Node2D
# owns: the Chapter 0 home scene: two rooms (bedroom, kitchen), the hard-cut transition
#   between them, and the story bible's age-9 jeep sequence: interacting with the box under
#   the bed leads into the scrape-the-contacts / twist-the-wire repair minigame, then repairs
#   the jeep and opens the stat screen, then carrying it into the kitchen (where both parents
#   stand, ignoring it) plays the "nobody looks up" beat once.
# does not own: the dialogue content itself (data/dialogue/ch0/), the minigame's own input
#   handling (see JeepRepairMinigame), or the systems it calls into (SkillSystem via the
#   increase_skill event, GameState for flags)

const JEEP_REPAIR_INTRO_DIALOGUE: String = "res://data/dialogue/ch0/c0_jeep_repair_intro.json"
const JEEP_REPAIR_OUTRO_DIALOGUE: String = "res://data/dialogue/ch0/c0_jeep_repair_outro.json"
const JEEP_KITCHEN_DIALOGUE: String = "res://data/dialogue/ch0/c0_jeep_kitchen.json"
const JEEP_REPAIR_MINIGAME_SCENE: String = "res://src/ui/jeep_repair_minigame.tscn"

@onready var _bedroom: Node2D = $Bedroom
@onready var _kitchen: Node2D = $Kitchen
@onready var _player: CharacterBody2D = $Player
@onready var _dialogue_runner: DialogueRunner = $DialogueRunner
@onready var _dialogue_box: DialogueBoxController = $UILayer/DialogueBox
@onready var _room_transition: RoomTransitionController = $RoomTransition
@onready var _box_interactable: Interactable = $Bedroom/BoxInteractable
@onready var _jeep_prop: Sprite2D = $Bedroom/JeepProp
@onready var _argument_ambience: AudioStreamPlayer2D = $Bedroom/ArgumentAmbience

var _in_dialogue: bool = false
var _transitioning: bool = false
var _pending_room: String = ""

func _ready() -> void:
	_dialogue_box.attach_runner(_dialogue_runner)
	_dialogue_runner.dialogue_finished.connect(_on_dialogue_finished)
	_box_interactable.interacted.connect(_on_box_interacted)
	$Bedroom/DoorTrigger.body_entered.connect(_on_bedroom_door_entered)
	$Kitchen/DoorTrigger.body_entered.connect(_on_kitchen_door_entered)
	_jeep_prop.visible = GameState.get_flag("jeep_repaired", false)
	if not GameState.get_flag("ch0_intro_heard", false):
		_argument_ambience.play()
		GameState.set_flag("ch0_intro_heard", true)

func _on_box_interacted() -> void:
	if _in_dialogue or GameState.get_flag("jeep_repaired", false):
		return
	_start_dialogue(JEEP_REPAIR_INTRO_DIALOGUE)

func _start_dialogue(path: String) -> void:
	_in_dialogue = true
	_dialogue_runner.load_dialogue(path)
	_dialogue_runner.start(GameState.pronoun, GameState.player_tokens)

func _on_dialogue_finished(dialogue_id: String) -> void:
	if dialogue_id == "c0_jeep_repair_intro":
		_start_jeep_minigame()
		return
	_in_dialogue = false
	if dialogue_id == "c0_jeep_repair_outro":
		_jeep_prop.visible = true
		_open_stat_screen()

func _start_jeep_minigame() -> void:
	var scene: PackedScene = load(JEEP_REPAIR_MINIGAME_SCENE)
	var minigame: JeepRepairMinigame = scene.instantiate()
	$UILayer.add_child(minigame)
	minigame.repair_complete.connect(_on_jeep_minigame_complete.bind(minigame), CONNECT_ONE_SHOT)

func _on_jeep_minigame_complete(minigame: JeepRepairMinigame) -> void:
	minigame.queue_free()
	_start_dialogue(JEEP_REPAIR_OUTRO_DIALOGUE)

func _open_stat_screen() -> void:
	var scene: PackedScene = load("res://src/scenes/shared/stat_screen.tscn")
	var stat_screen: Control = scene.instantiate()
	$UILayer.add_child(stat_screen)
	stat_screen.closed.connect(stat_screen.queue_free)

func _on_bedroom_door_entered(body: Node2D) -> void:
	if _transitioning or not body.is_in_group("player"):
		return
	_pending_room = "kitchen"
	_transitioning = true
	_room_transition.hold_reached.connect(_on_transition_hold, CONNECT_ONE_SHOT)
	_room_transition.cut()

func _on_kitchen_door_entered(body: Node2D) -> void:
	if _transitioning or not body.is_in_group("player"):
		return
	_pending_room = "bedroom"
	_transitioning = true
	_room_transition.hold_reached.connect(_on_transition_hold, CONNECT_ONE_SHOT)
	_room_transition.cut()

func _on_transition_hold() -> void:
	if _pending_room == "kitchen":
		_bedroom.visible = false
		_kitchen.visible = true
		_player.global_position = _kitchen.get_node("Spawn").global_position
	else:
		_kitchen.visible = false
		_bedroom.visible = true
		_player.global_position = _bedroom.get_node("Spawn").global_position
	_transitioning = false
	if _pending_room == "kitchen":
		_maybe_start_kitchen_scene()
	_pending_room = ""

func _maybe_start_kitchen_scene() -> void:
	if _in_dialogue:
		return
	if not GameState.get_flag("jeep_repaired", false):
		return
	if GameState.get_flag("c0_jeep_kitchen_seen", false):
		return
	_start_dialogue(JEEP_KITCHEN_DIALOGUE)
