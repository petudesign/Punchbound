extends CharacterBody2D

const UPPERCUT = preload("res://data/attacks/uppercut.tres")
const DOWN_KICK = preload("res://data/attacks/down_kick.tres")

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
var _head_landing_cooldown: float = 0.0
var _last_head_enemy: Node2D
@onready var combat = $Combat
@onready var sprite: Sprite2D = $Sprite2D


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
	if Input.is_action_just_pressed("crouch") and not is_on_floor() and not combat.attacking:
		if combat.start_attack(DOWN_KICK):
			velocity.y = maxf(velocity.y, 220.0)
	if combat.freeze_remaining > 0.0:
		return
	_head_landing_cooldown = maxf(0.0, _head_landing_cooldown - delta)
	if is_instance_valid(_last_head_enemy) and global_position.y > _last_head_enemy.global_position.y + 8.0:
		_last_head_enemy = null
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

	# The player is anchored in the arena. Direction keys turn and attack;
	# enemies create the movement pressure from both sides.
	velocity.x = 0.0
	if not is_zero_approx(_attack_direction) and not combat.attacking and _attack_buffer_remaining > 0.0:
		combat.facing = _attack_direction
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
	_update_visual()
	var falling_speed: float = velocity.y
	move_and_slide()
	if falling_speed > 80.0 and _head_landing_cooldown <= 0.0:
		for body in $HeadSensor.get_overlapping_bodies():
			if body.is_in_group("enemies") and body != _last_head_enemy and global_position.y <= body.global_position.y:
				global_position.y = body.global_position.y - 64.0
				# Bounce away immediately so the enemy can never carry the player.
				velocity.y = -260.0
				body.get_node("Combat").stun(0.45)
				_head_landing_cooldown = 0.28
				_last_head_enemy = body
				break


func _update_visual() -> void:
	sprite.flip_h = combat.facing < 0.0
	if combat.attacking:
		if combat.current_attack == UPPERCUT:
			sprite.texture = $SpriteFrames.get_meta("uppercut")
		elif combat.current_attack == DOWN_KICK:
			sprite.texture = $SpriteFrames.get_meta("down_kick")
		else:
			sprite.texture = $SpriteFrames.get_meta("punch")
		sprite.position.y = -69.0
	elif combat.crouching:
		sprite.texture = $SpriteFrames.get_meta("crouch")
		sprite.position.y = -69.0
	elif not is_on_floor():
		sprite.texture = $SpriteFrames.get_meta("jump")
		sprite.position.y = -69.0
	else:
		sprite.texture = $SpriteFrames.get_meta("idle")
		sprite.position.y = -69.0
