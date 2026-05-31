extends Node3D

const MapGeneratorScript = preload("res://scripts/MapGenerator.gd")
const WeaponManagerScript = preload("res://scripts/WeaponManager.gd")
const WaveManagerScript = preload("res://scripts/WaveManager.gd")
const HUDScript = preload("res://scripts/HUD.gd")

var points: int = 0

var map_generator: Node
var weapon_manager: Node
var wave_manager: Node
var hud: CanvasLayer
var nearby_interactable: Node
var interact_distance: float = 5.0

@onready var player: CharacterBody3D = $Player
@onready var camera: Camera3D = $Player/Camera3D

func _ready() -> void:
	add_to_group("game_manager")
	_build_foundation()

func _build_foundation() -> void:
	map_generator = MapGeneratorScript.new()
	map_generator.name = "MapGenerator"
	add_child(map_generator)
	map_generator.call("build_test_map", self)
	player.global_position = map_generator.call("get_player_start") as Vector3

	weapon_manager = WeaponManagerScript.new()
	weapon_manager.name = "WeaponManager"
	player.add_child(weapon_manager)
	weapon_manager.call("setup", player, camera, self)

	wave_manager = WaveManagerScript.new()
	wave_manager.name = "WaveManager"
	add_child(wave_manager)
	wave_manager.call("setup", self, player, map_generator)

	hud = HUDScript.new()
	hud.name = "HUD"
	add_child(hud)
	hud.call("setup", self, player, weapon_manager, wave_manager)

	if player.has_signal("died"):
		player.died.connect(_on_player_died)

	wave_manager.call("start_next_wave")

func _process(_delta: float) -> void:
	_update_interaction_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_try_interact()

func add_points(amount: int) -> void:
	points += amount

func spend_points(amount: int) -> bool:
	if points < amount:
		return false

	points -= amount
	return true

func on_zombie_killed(zombie: Node) -> void:
	add_points(zombie.get("points_value") as int)
	wave_manager.call("on_zombie_killed", zombie)

func get_zombies_remaining() -> int:
	if wave_manager == null:
		return 0
	return wave_manager.call("get_zombies_remaining") as int

func get_current_wave() -> int:
	if wave_manager == null:
		return 0
	return wave_manager.get("current_wave") as int

func _on_player_died() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _update_interaction_prompt() -> void:
	nearby_interactable = _find_nearest_interactable()

	var prompt: String = ""
	if nearby_interactable != null:
		prompt = nearby_interactable.call("get_prompt", points) as String

	if hud != null and hud.has_method("set_prompt"):
		hud.call("set_prompt", prompt)

func _try_interact() -> void:
	if nearby_interactable == null:
		return

	var opened: bool = nearby_interactable.call("interact", self) as bool
	if not opened:
		return

	var gate: String = str(nearby_interactable.get("spawn_gate"))
	if map_generator != null and map_generator.has_method("unlock_spawn_gate"):
		map_generator.call("unlock_spawn_gate", gate)

	_update_interaction_prompt()

func _find_nearest_interactable() -> Node:
	var best: Node = null
	var best_distance: float = interact_distance

	for candidate in get_tree().get_nodes_in_group("buyable_doors"):
		var door: Node3D = candidate as Node3D
		if door == null:
			continue
		if bool(door.get("is_open")):
			continue

		var distance: float = player.global_position.distance_to(door.global_position)
		if distance < best_distance:
			best_distance = distance
			best = door

	return best
