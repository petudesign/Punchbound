extends CharacterBody2D

@export var move_speed: float = 340.0
@export var jump_speed: float = 610.0
@export var gravity: float = 1800.0
@export var coyote_time: float = 0.08
@export var jump_buffer_time: float = 0.10

var _coyote_remaining: float = 0.0
var _jump_buffer_remaining: float = 0.0


func _physics_process(delta: float) -> void:
	_coyote_remaining = coyote_time if is_on_floor() else maxf(0.0, _coyote_remaining - delta)
	_jump_buffer_remaining = maxf(0.0, _jump_buffer_remaining - delta)
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_remaining = jump_buffer_time

	velocity.x = Input.get_axis("move_left", "move_right") * move_speed
	if not is_on_floor():
		velocity.y += gravity * delta
	if _jump_buffer_remaining > 0.0 and _coyote_remaining > 0.0:
		velocity.y = -jump_speed
		_jump_buffer_remaining = 0.0
		_coyote_remaining = 0.0
	move_and_slide()
