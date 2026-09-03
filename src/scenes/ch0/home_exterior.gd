extends Node2D
# owns: the chapter 0 home exterior: the yard the player starts in, the front door that leads
#   inside (per docs/STORY.md 3.6, the only door in the game that ever actually closes, though
#   that closing beat belongs to the chapter's ending, not here), and the path east to the
#   family's warehouse at the lake edge.
# does not own: what's inside the house (see home.tscn) or the warehouse (see
#   warehouse_exterior.tscn), or a way back out of the house, since nothing built yet needs one

const HOME_SCENE: String = "res://src/scenes/ch0/home.tscn"
const WAREHOUSE_EXTERIOR_SCENE: String = "res://src/scenes/ch0/warehouse_exterior.tscn"

@onready var _door_trigger: Area2D = $DoorTrigger
@onready var _path_east_trigger: Area2D = $PathEastTrigger
@onready var _player: CharacterBody2D = $Player

func _ready() -> void:
	_door_trigger.body_entered.connect(_on_door_entered)
	_path_east_trigger.body_entered.connect(_on_path_east_entered)
	if GameState.get_flag("ch0_last_exit", "") == "warehouse_exterior":
		_player.global_position = $SpawnFromWarehouse.global_position

func _on_door_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	get_tree().change_scene_to_file(HOME_SCENE)

func _on_path_east_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameState.set_flag("ch0_last_exit", "home_exterior")
	get_tree().change_scene_to_file(WAREHOUSE_EXTERIOR_SCENE)
