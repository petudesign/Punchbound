extends Node2D

signal damaged(amount: int)
signal died
signal landed_hit

@export var attack: Resource
@export var max_health: int = 100
@export var enemy: bool = false

var health: int
var facing: float = 1.0
var crouching: bool = false
var stun_remaining: float = 0.0
var freeze_remaining: float = 0.0
var invulnerability_remaining: float = 0.0
var attacking: bool = false
var elapsed: float = 0.0
var attack_facing: float = 1.0
var current_attack: Resource
var _hit_targets: Array[int] = []
var _flash: float = 0.0
var _hurt_shape := RectangleShape2D.new()
var _hit_shape := RectangleShape2D.new()
var _hurt_collision := CollisionShape2D.new()
var _query := PhysicsShapeQueryParameters2D.new()


func _ready() -> void:
	process_physics_priority = -10
	health = max_health
	current_attack = attack
	var hurtbox := Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 4 if enemy else 2
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	_hurt_shape.size = Vector2(38, 64)
	_hurt_collision.shape = _hurt_shape
	_hurt_collision.position.y = -32.0
	hurtbox.add_child(_hurt_collision)
	add_child(hurtbox)
	_hit_shape.size = Vector2(attack.reach, attack.height)
	_query.shape = _hit_shape
	_query.collision_mask = 2 if enemy else 4
	_query.collide_with_areas = true
	_query.collide_with_bodies = false


func set_crouching(value: bool) -> void:
	crouching = value
	_hurt_shape.size.y = 28.0 if value else 64.0
	_hurt_collision.position.y = -_hurt_shape.size.y / 2.0


func start_attack(selected_attack: Resource = null) -> bool:
	if health <= 0 or attacking or stun_remaining > 0.0 or freeze_remaining > 0.0:
		return false
	attacking = true
	current_attack = attack if selected_attack == null else selected_attack
	_hit_shape.size = Vector2(current_attack.reach, current_attack.height)
	elapsed = 0.0
	attack_facing = facing
	_hit_targets.clear()
	return true


func _physics_process(delta: float) -> void:
	queue_redraw()
	if freeze_remaining > 0.0:
		freeze_remaining = maxf(0.0, freeze_remaining - delta)
		return
	stun_remaining = maxf(0.0, stun_remaining - delta)
	invulnerability_remaining = maxf(0.0, invulnerability_remaining - delta)
	_flash = maxf(0.0, _flash - delta)
	if health <= 0 or not attacking:
		return
	elapsed += delta
	if elapsed >= current_attack.startup and elapsed < current_attack.startup + current_attack.active:
		_query.transform = Transform2D(0.0, global_position + _attack_center())
		for result in get_world_2d().direct_space_state.intersect_shape(_query):
			var target = result.collider.get_parent()
			var target_id: int = target.get_instance_id()
			if target_id not in _hit_targets:
				_hit_targets.append(target_id)
				if target.receive_hit(current_attack, attack_facing):
					freeze_remaining = current_attack.hitstop
					landed_hit.emit()
	if elapsed >= current_attack.startup + current_attack.active + current_attack.recovery:
		attacking = false


func stun(duration: float) -> void:
	if health <= 0:
		return
	attacking = false
	stun_remaining = maxf(stun_remaining, duration)
	queue_redraw()


func receive_hit(data: Resource, direction: float) -> bool:
	if health <= 0 or invulnerability_remaining > 0.0:
		return false
	health = maxi(0, health - data.damage)
	attacking = false
	stun_remaining = data.stun
	freeze_remaining = data.hitstop
	invulnerability_remaining = 0.08 if enemy else 0.65
	_flash = 0.16
	get_parent().velocity = Vector2(direction * data.knockback, -data.launch_speed)
	damaged.emit(data.damage)
	if health == 0:
		died.emit()
	return true


func _attack_center() -> Vector2:
	# Enemy punches pass above a crouching hurtbox; down kick reaches below player.
	var elevation: float = 18.0 if crouching and not enemy else current_attack.elevation
	return Vector2(attack_facing * (19.0 + current_attack.reach / 2.0), -elevation)


func _draw() -> void:
	if health <= 0:
		return
	var body_height: float = 28.0 if crouching else 64.0
	if _flash > 0.0:
		draw_rect(Rect2(-21, -body_height - 2, 42, body_height + 4), Color.WHITE)
	if enemy:
		draw_rect(Rect2(-23, -78, 46, 5), Color(0.2, 0.2, 0.25))
		draw_rect(Rect2(-23, -78, 46.0 * health / max_health, 5), Color(1.0, 0.4, 0.36))
		if stun_remaining > 0.0:
			draw_arc(Vector2(0, -90), 14.0, 0.0, TAU, 16, Color(0.4, 0.85, 1.0), 2.0)
	if attacking:
		var rect := Rect2(_attack_center() - _hit_shape.size / 2.0, _hit_shape.size)
		if elapsed < current_attack.startup:
			draw_rect(rect, Color(1.0, 0.72, 0.2, 0.8), false, 2.0)
			if enemy:
				draw_line(Vector2(-6, -100), Vector2(-6, -85), Color.YELLOW, 4.0)
		elif elapsed < current_attack.startup + current_attack.active:
			draw_rect(rect, Color(1.0, 0.90, 0.55, 0.9))
