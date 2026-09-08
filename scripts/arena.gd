extends Node2D

const ENEMY = preload("res://scenes/enemy.tscn")
@export var encounters_enabled: bool = true
var defeated: int = 0
var round_number: int = 0
var _spawn_remaining: float = 1.0
@onready var player = $Player
@onready var status: Label = $HUD/Margin/Instructions


func _ready() -> void:
	player.get_node("Combat").died.connect(_game_over)
	$HUD/Restart.pressed.connect(func(): get_tree().reload_current_scene())


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return
	var hp: int = player.get_node("Combat").health
	status.text = "PUNCHBOUND / COMBAT LAB     HP %d / 100     DEFEATED %d\n" % [hp, defeated]
	status.text += "A/D or Left/Right: turn + punch   W/Up: jump   S/Down: crouch   R: restart\n"
	status.text += "Crouch + jump: uppercut. Land on enemies to stun. Yellow = incoming high punch." if hp > 0 else "DOWN — Press R or use Restart to try again."
	if not encounters_enabled or hp <= 0:
		return
	if get_tree().get_nodes_in_group("enemies").is_empty():
		_spawn_remaining -= delta
		if _spawn_remaining <= 0.0:
			_spawn_encounter()
			_spawn_remaining = 1.2


func _spawn_encounter() -> void:
	round_number += 1
	# Introduce one side at a time, then bring pressure from both sides.
	var count: int = 1 if round_number <= 2 else 2
	for index in range(count):
		var enemy = ENEMY.instantiate()
		var left_side: bool = ((round_number + index) % 2) == 1
		enemy.position = Vector2(80 if left_side else 1072, 560)
		enemy.target = player
		add_child(enemy)
		enemy.get_node("Combat").died.connect(func(): defeated += 1)


func _game_over() -> void:
	$HUD/Restart.show()
	$HUD/Restart.grab_focus()
