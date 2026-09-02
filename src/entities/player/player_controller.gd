class_name PlayerController
extends CharacterBody2D
# owns: 4-direction input-driven movement, pixel snapping, and facing state
# does not own: animation playback, height/shadow (see HeightComponent), camera behaviour

enum Facing { DOWN, UP, LEFT, RIGHT }

@export var move_speed: float = 60.0

var facing: Facing = Facing.DOWN

func _ready() -> void:
	# lets a TallPropOcclusionArea find and fade this entity's visual (see F-025)
	add_to_group("occludable")
	# lets an Interactable's Area2D tell the player apart from any other body it detects
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	var input_vector: Vector2 = _read_input_vector()
	velocity = input_vector * move_speed
	move_and_slide()

	if input_vector != Vector2.ZERO:
		facing = _facing_from_vector(input_vector)

	# all sprite positions snap to whole pixels, per DESIGN.md section 1
	global_position = global_position.round()

func is_moving() -> bool:
	return velocity.length() > 0.01

func _read_input_vector() -> Vector2:
	var input_vector: Vector2 = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	return input_vector

func _facing_from_vector(input_vector: Vector2) -> Facing:
	if absf(input_vector.x) > absf(input_vector.y):
		return Facing.RIGHT if input_vector.x > 0.0 else Facing.LEFT
	return Facing.DOWN if input_vector.y > 0.0 else Facing.UP
