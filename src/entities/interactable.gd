class_name Interactable
extends Area2D
# owns: detecting whether the player is in range and turning an "interact" press into one
#   signal. that is the whole job.
# does not own: what happens on interaction (a scene's own script connects to `interacted`),
#   or how the range is shaped (the caller sizes the CollisionShape2D in the editor/scene file)

signal interacted

var _player_in_range: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("interact"):
		interacted.emit()
		get_viewport().set_input_as_handled()
