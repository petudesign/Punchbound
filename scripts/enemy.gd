extends CharacterBody2D

@export var move_speed: float = 125.0
var target: CharacterBody2D
@onready var combat = $Combat


func _ready() -> void:
	combat.died.connect(_die)


func _physics_process(delta: float) -> void:
	if combat.freeze_remaining > 0.0:
		return
	if not is_on_floor():
		velocity.y += 1800.0 * delta
	if combat.health <= 0 or combat.stun_remaining > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 650.0 * delta)
	elif not is_instance_valid(target) or target.get_node("Combat").health <= 0:
		velocity.x = 0.0
	elif combat.attacking:
		velocity.x = 0.0
	else:
		var offset: Vector2 = target.global_position - global_position
		if absf(offset.x) > 4.0:
			combat.facing = signf(offset.x)
		if absf(offset.x) < 74.0 and absf(offset.y) < 40.0:
			velocity.x = 0.0
			combat.start_attack()
		else:
			velocity.x = combat.facing * move_speed
	move_and_slide()


func _die() -> void:
	set_collision_layer_value(4, false)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.22)
	tween.tween_callback(queue_free)
