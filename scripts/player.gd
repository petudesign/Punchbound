extends CharacterBody2D

const UPPERCUT = preload("res://data/attacks/uppercut.tres")

@export var move_speed: float = 340.0
@export var jump_speed: float = 610.0
@export var gravity: float = 1800.0
@export var coyote_time: float = 0.08
@export var jump_buffer_time: float = 0.10

var _coyote_remaining: float = 0.0
var _jump_buffer_remaining: float = 0.0
var _attack_buffer_remaining: float = 0.0
var _attack_direction: float = 1.0
var _uppercut_buffered: bool = false
@onready var combat = $Combat


func _physics_process(delta: float) -> void:
	var direction_pressed: float = 0.0
	if Input.is_action_just_pressed("move_left"):
		direction_pressed -= 1.0
	if Input.is_action_just_pressed("move_right"):
		direction_pressed += 1.0
	if not is_zero_approx(direction_pressed):
		_attack_buffer_remaining = 0.15
		_attack_direction = direction_pressed
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_remaining = jump_buffer_time
		_uppercut_buffered = Input.is_action_pressed("crouch") and is_on_floor()
	if combat.freeze_remaining > 0.0:
		return
	_attack_buffer_remaining = maxf(0.0, _attack_buffer_remaining - delta)
	_jump_buffer_remaining = maxf(0.0, _jump_buffer_remaining - delta)
	if combat.health <= 0 or combat.stun_remaining > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		velocity.y += gravity * delta
		move_and_slide()
		return
	combat.set_crouching(Input.is_action_pressed("crouch") and is_on_floor())
	$Body.scale.y = 0.4375 if combat.crouching else 1.0
	$CollisionShape2D.shape.size.y = 28.0 if combat.crouching else 64.0
	$CollisionShape2D.position.y = -$CollisionShape2D.shape.size.y / 2.0
	_coyote_remaining = coyote_time if is_on_floor() else maxf(0.0, _coyote_remaining - delta)

	velocity.x = Input.get_axis("move_left", "move_right") * move_speed
	if combat.crouching:
		velocity.x *= 0.3
	if not is_zero_approx(velocity.x) and not combat.attacking:
		combat.facing = signf(velocity.x)
	if not is_on_floor():
		velocity.y += gravity * delta
	if _jump_buffer_remaining > 0.0 and _coyote_remaining > 0.0:
		# A crouch jump waits for recovery, then starts jump and uppercut together.
		if _uppercut_buffered and (combat.attacking or not combat.start_attack(UPPERCUT)):
			move_and_slide()
			return
		combat.set_crouching(false)
		$Body.scale.y = 1.0
		$CollisionShape2D.shape.size.y = 64.0
		$CollisionShape2D.position.y = -32.0
		velocity.y = -jump_speed
		_jump_buffer_remaining = 0.0
		_coyote_remaining = 0.0
		if _uppercut_buffered:
			_attack_buffer_remaining = 0.0
		_uppercut_buffered = false
	if _attack_buffer_remaining > 0.0 and not combat.attacking:
		combat.facing = _attack_direction
		if combat.start_attack():
			_attack_buffer_remaining = 0.0
	var falling_speed: float = velocity.y
	move_and_slide()
	if falling_speed > 80.0:
		for index in range(get_slide_collision_count()):
			var collision := get_slide_collision(index)
			var body := collision.get_collider()
			if collision.get_normal().y < -0.5 and body.is_in_group("enemies"):
				body.get_node("Combat").stun(0.45)
