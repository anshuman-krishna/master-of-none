extends Node2D
# owns: the chapter 0 home exterior: the yard the player starts in, and the front door that
#   leads inside. per docs/STORY.md 3.6, this door is the only one in the game that ever
#   actually closes, though that closing beat belongs to the chapter's ending, not here.
# does not own: what's inside (see home.tscn), or a way back out, since nothing in chapter 0's
#   built content yet needs to leave the house once entered

const HOME_SCENE: String = "res://src/scenes/ch0/home.tscn"

@onready var _door_trigger: Area2D = $DoorTrigger

func _ready() -> void:
	_door_trigger.body_entered.connect(_on_door_entered)

func _on_door_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	get_tree().change_scene_to_file(HOME_SCENE)
