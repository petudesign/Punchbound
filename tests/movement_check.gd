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
	var player = arena.get_node("Player")
	await _frames(5)
	_check(player.is_on_floor(), "Player should settle on the floor")
	var start_x: float = player.position.x
	Input.action_press("move_right")
	await _frames(12)
	Input.action_release("move_right")
	_check(is_equal_approx(player.position.x, start_x), "Direction action should not move anchored player")
	await _frames(2)
	_check(is_zero_approx(player.velocity.x), "Releasing movement should stop immediately")
	Input.action_press("move_left")
	await _frames(12)
	Input.action_release("move_left")
	_check(is_equal_approx(player.position.x, start_x), "Left action should not move anchored player")
	Input.action_press("jump")
	await _frames(4)
	Input.action_release("jump")
	_check(player.position.y < 550.0, "Jump should lift player off the floor")
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	_check(player.velocity.y > -player.jump_speed + 50.0, "Airborne input must not grant a second jump")
	await _frames(60)
	_check(player.is_on_floor(), "Player should land after jumping")
	_check(is_equal_approx(player.position.x, start_x), "Arena should keep player centered")
	print("Movement check: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
