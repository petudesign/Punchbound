extends SceneTree

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var arena = load("res://scenes/arena.tscn").instantiate()
	arena.encounters_enabled = false
	root.add_child(arena)
	current_scene = arena
	var player = arena.get_node("Player")
	var player_combat = player.get_node("Combat")
	var enemy = load("res://scenes/enemy.tscn").instantiate()
	enemy.position = Vector2(630, 560)
	enemy.target = player
	arena.add_child(enemy)
	enemy.set_physics_process(false)
	var enemy_combat = enemy.get_node("Combat")
	await _frames(5)
	Input.action_press("move_right")
	await _frames(1)
	Input.action_release("move_right")
	await _frames(2)
	_check(enemy_combat.health == 60, "Startup must not damage the enemy")
	await _frames(5)
	_check(enemy_combat.health == 40, "Active punch must hit an overlapping hurtbox")
	_check(enemy_combat.freeze_remaining > 0.0, "Hit should apply hitstop")
	_check(enemy.velocity.x > 0.0, "Punch should knock enemy away")
	await _frames(35)
	_check(enemy_combat.health == 40, "One swing must damage each target only once")
	Input.action_press("move_left")
	await _frames(1)
	Input.action_release("move_left")
	await _frames(30)
	_check(enemy_combat.health == 40, "Punch facing away must miss")
	Input.action_press("crouch")
	await _frames(3)
	_check(player_combat.crouching, "Crouch input should shrink hurtbox")
	enemy_combat.facing = -1.0
	enemy_combat.start_attack()
	await _frames(80)
	_check(player_combat.health == 100, "Crouching must avoid the enemy high punch")
	Input.action_release("crouch")
	await _frames(3)
	enemy_combat.start_attack()
	await _frames(36)
	_check(player_combat.health == 88, "Standing in enemy punch should receive damage")
	_check(not player_combat.receive_hit(enemy_combat.attack, -1.0), "Damage grace period should prevent stacked hits")
	await _frames(65)
	# Normal jump must not become an uppercut.
	player.position = Vector2(300, 560)
	player.velocity = Vector2.ZERO
	await _frames(3)
	Input.action_press("jump")
	await _frames(3)
	Input.action_release("jump")
	_check(not player_combat.attacking and player.velocity.y < 0.0, "Standing jump must be a normal jump")
	await _frames(60)
	player.position = Vector2(576, 560)
	player.velocity = Vector2.ZERO
	player_combat.facing = 1.0
	Input.action_press("crouch")
	await _frames(3)
	Input.action_press("jump")
	await _frames(4)
	Input.action_release("jump")
	Input.action_release("crouch")
	_check(player_combat.current_attack == load("res://data/attacks/uppercut.tres"), "Crouch jump must select uppercut")
	_check(player.velocity.y < 0.0 and not player_combat.crouching, "Uppercut should rise out of crouch")
	_check(enemy_combat.health == 15 and enemy.velocity.y < -400.0, "Uppercut should hit and launch nearby enemy")
	await _frames(65)
	# Descending feet land on the enemy's one-way body and interrupt its wind-up.
	player.position = Vector2(630, 420)
	player.velocity = Vector2(0, 150)
	enemy_combat.start_attack()
	for frame in range(25):
		await _frames(1)
		if enemy_combat.stun_remaining > 0.0:
			break
	_check(player.is_on_floor() and player.position.y < 500.0, "Player should land on enemy head")
	_check(enemy_combat.stun_remaining > 0.0 and not enemy_combat.attacking, "Head landing should stun and interrupt")
	_check(enemy_combat.health == 15, "Head landing must not deal damage")
	await _frames(40)
	_check(enemy_combat.stun_remaining == 0.0, "Standing on enemy must not repeatedly stun it")
	player.position = Vector2(570, 560)
	player.velocity = Vector2.ZERO
	enemy_combat.invulnerability_remaining = 10.0
	await _frames(3)
	Input.action_press("move_right")
	await _frames(40)
	_check(player.position.x > 700.0, "Enemy one-way body must not block side movement")
	_check(not player_combat.attacking, "Holding direction must not repeatedly punch")
	Input.action_release("move_right")
	var lethal = enemy_combat.attack.duplicate()
	lethal.damage = 200
	player_combat.receive_hit(lethal, -1.0)
	_check(player_combat.health == 0, "Lethal damage should clamp health to zero")
	_check(not player_combat.start_attack(), "Dead player must not attack")
	_check(arena.get_node("HUD/Restart").visible, "Death should offer restart")
	arena.get_node("HUD/Restart").pressed.emit()
	await _frames(5)
	arena = current_scene
	_check(arena.get_node("Player/Combat").health == 100, "Restart should restore health")
	await _frames(70)
	var enemies := get_nodes_in_group("enemies")
	_check(enemies.size() == 1, "First encounter should spawn one enemy")
	if not enemies.is_empty():
		enemy = enemies[0]
		var initial_distance: float = absf(enemy.position.x - arena.get_node("Player").position.x)
		await _frames(30)
		_check(absf(enemy.position.x - arena.get_node("Player").position.x) < initial_distance, "Enemy AI should approach player")
		enemy.get_node("Combat").receive_hit(lethal, 1.0)
		await _frames(110)
		_check(arena.defeated == 1, "Enemy death should count once")
		_check(get_nodes_in_group("enemies").size() == 1, "Defeating enemy should start a new encounter")
	print("Combat check: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
