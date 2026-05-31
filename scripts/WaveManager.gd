extends Node
const ZombieScript = preload("res://scripts/Zombie.gd")

@export var base_zombie_count: int = 3
@export var zombies_per_wave: int = 2
@export var first_spawn_count: int = 2
@export var spawn_interval: float = 1.35
@export var spawn_point_cooldown: float = 2.5
@export var health_per_wave: int = 15

var game_manager: Node
var player: Node3D
var map_generator: Node
var spawn_points: Array[Vector3] = []
var spawn_cooldowns: Array[float] = []
var current_wave: int = 0
var alive_zombies: Array[Node] = []
var spawning_next_wave: bool = false
var spawn_sequence_active: bool = false
var spawn_cursor: int = 0
var pending_zombies_to_spawn: int = 0

func setup(manager: Node, target_player: Node3D, map_node: Node) -> void:
	game_manager = manager
	player = target_player
	map_generator = map_node
	_refresh_spawn_points()

func _process(delta: float) -> void:
	for index in spawn_cooldowns.size():
		spawn_cooldowns[index] = max(spawn_cooldowns[index] - delta, 0.0)

func start_next_wave() -> void:
	_refresh_spawn_points()
	if spawn_points.is_empty():
		return

	spawning_next_wave = false
	spawn_sequence_active = false
	current_wave += 1
	var count: int = base_zombie_count + ((current_wave - 1) * zombies_per_wave)
	pending_zombies_to_spawn = count

	_spawn_pending_zombies(min(first_spawn_count, pending_zombies_to_spawn))

	if pending_zombies_to_spawn > 0:
		_spawn_delayed_zombies()

func on_zombie_killed(zombie: Node) -> void:
	_prune_zombies()
	alive_zombies.erase(zombie)
	if get_zombies_remaining() == 0 and not spawning_next_wave:
		spawning_next_wave = true
		_start_next_wave_after_delay()

func get_zombies_remaining() -> int:
	_prune_zombies()
	return alive_zombies.size() + pending_zombies_to_spawn

func _refresh_spawn_points() -> void:
	if map_generator != null and map_generator.has_method("get_zombie_spawns"):
		var points: Array = map_generator.call("get_zombie_spawns")
		spawn_points.clear()
		for point in points:
			spawn_points.append(point as Vector3)
		_resize_spawn_cooldowns()

func _spawn_zombie(spawn_position: Vector3) -> void:
	var zombie: CharacterBody3D = ZombieScript.new() as CharacterBody3D
	zombie.name = "Zombie"
	zombie.call("setup", player, game_manager, map_generator)
	zombie.call("configure_for_wave", current_wave, health_per_wave)
	get_parent().add_child(zombie)
	zombie.global_position = spawn_position
	alive_zombies.append(zombie)

func _start_next_wave_after_delay() -> void:
	await get_tree().create_timer(2.0).timeout
	start_next_wave()

func _spawn_delayed_zombies() -> void:
	if spawn_sequence_active:
		return

	spawn_sequence_active = true

	while pending_zombies_to_spawn > 0:
		await get_tree().create_timer(spawn_interval).timeout
		_refresh_spawn_points()
		_spawn_pending_zombies(1)

	spawn_sequence_active = false

func _spawn_pending_zombies(amount: int) -> void:
	var spawned: int = 0
	var attempts: int = max(spawn_points.size(), 1)

	while spawned < amount and pending_zombies_to_spawn > 0 and attempts > 0:
		attempts -= 1
		var spawn_result: Dictionary = _find_safe_spawn()
		if not bool(spawn_result["found"]):
			continue

		_spawn_zombie(spawn_result["position"] as Vector3)
		pending_zombies_to_spawn -= 1
		spawned += 1

func _find_safe_spawn() -> Dictionary:
	if spawn_points.is_empty():
		return {"found": false, "position": Vector3.ZERO}

	for step in spawn_points.size():
		var index: int = (spawn_cursor + step) % spawn_points.size()
		if index < spawn_cooldowns.size() and spawn_cooldowns[index] > 0.0:
			continue

		var candidate: Vector3 = spawn_points[index]
		if _is_spawn_clear(candidate):
			spawn_cursor = (index + 1) % spawn_points.size()
			if index < spawn_cooldowns.size():
				spawn_cooldowns[index] = spawn_point_cooldown
			return {"found": true, "position": candidate}

	return {"found": false, "position": Vector3.ZERO}

func _is_spawn_clear(spawn_position: Vector3) -> bool:
	if get_tree() == null:
		return false

	var shape := CapsuleShape3D.new()
	shape.radius = 0.8
	shape.height = 2.0

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), spawn_position + Vector3(0, 1.05, 0))
	query.collision_mask = 1
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var space_state: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var results: Array = space_state.intersect_shape(query, 8)
	return results.is_empty()

func _prune_zombies() -> void:
	for index in range(alive_zombies.size() - 1, -1, -1):
		if not is_instance_valid(alive_zombies[index]):
			alive_zombies.remove_at(index)

func _resize_spawn_cooldowns() -> void:
	while spawn_cooldowns.size() < spawn_points.size():
		spawn_cooldowns.append(0.0)
	while spawn_cooldowns.size() > spawn_points.size():
		spawn_cooldowns.pop_back()
