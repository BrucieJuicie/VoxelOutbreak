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

@onready var player: CharacterBody3D = $Player
@onready var camera: Camera3D = $Player/Camera3D

func _ready() -> void:
	add_to_group("game_manager")
	_build_foundation()

func _build_foundation() -> void:
	map_generator = MapGeneratorScript.new()
	map_generator.name = "MapGenerator"
	add_child(map_generator)
	map_generator.call("build_test_map")
	player.global_position = map_generator.call("get_player_start") as Vector3

	weapon_manager = WeaponManagerScript.new()
	weapon_manager.name = "WeaponManager"
	player.add_child(weapon_manager)
	weapon_manager.call("setup", player, camera, self)

	wave_manager = WaveManagerScript.new()
	wave_manager.name = "WaveManager"
	add_child(wave_manager)
	wave_manager.call("setup", self, player, map_generator.call("get_zombie_spawns"))

	hud = HUDScript.new()
	hud.name = "HUD"
	add_child(hud)
	hud.call("setup", self, player, weapon_manager, wave_manager)

	if player.has_signal("died"):
		player.died.connect(_on_player_died)

	wave_manager.call("start_next_wave")

func add_points(amount: int) -> void:
	points += amount

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
