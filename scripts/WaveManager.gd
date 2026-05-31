extends Node
const ZombieScript = preload("res://scripts/Zombie.gd")

@export var base_zombie_count: int = 3
@export var zombies_per_wave: int = 2

var game_manager: Node
var player: Node3D
var spawn_points: Array[Vector3] = []
var current_wave: int = 0
var alive_zombies: Array[Node] = []
var spawning_next_wave: bool = false

func setup(manager: Node, target_player: Node3D, points: Array[Vector3]) -> void:
	game_manager = manager
	player = target_player
	spawn_points = points

func start_next_wave() -> void:
	if spawn_points.is_empty():
		return

	spawning_next_wave = false
	current_wave += 1
	var count := base_zombie_count + ((current_wave - 1) * zombies_per_wave)

	for index in count:
		var spawn_position := spawn_points[index % spawn_points.size()]
		_spawn_zombie(spawn_position)

func on_zombie_killed(zombie: Node) -> void:
	alive_zombies.erase(zombie)
	if alive_zombies.is_empty() and not spawning_next_wave:
		spawning_next_wave = true
		_start_next_wave_after_delay()

func get_zombies_remaining() -> int:
	return alive_zombies.size()

func _spawn_zombie(spawn_position: Vector3) -> void:
	var zombie := ZombieScript.new() as CharacterBody3D
	zombie.name = "Zombie"
	zombie.call("setup", player, game_manager)
	get_parent().add_child(zombie)
	zombie.global_position = spawn_position
	alive_zombies.append(zombie)

func _start_next_wave_after_delay() -> void:
	await get_tree().create_timer(2.0).timeout
	start_next_wave()
