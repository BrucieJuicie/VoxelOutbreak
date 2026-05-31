extends Node

signal ammo_changed(ammo: int, reserve_ammo: int)

@export var damage: int = 25
@export var fire_rate: float = 0.25
@export var shot_range: float = 70.0
@export var magazine_size: int = 12
@export var reserve_ammo: int = 48

var ammo: int = magazine_size
var cooldown: float = 0.0
var player: Node3D
var camera: Camera3D
var game_manager: Node

func setup(player_node: Node3D, camera_node: Camera3D, manager: Node) -> void:
	player = player_node
	camera = camera_node
	game_manager = manager
	ammo = magazine_size
	ammo_changed.emit(ammo, reserve_ammo)

func _process(delta: float) -> void:
	cooldown = max(cooldown - delta, 0.0)

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		try_fire()

	if Input.is_key_pressed(KEY_R):
		reload()

func try_fire() -> void:
	if camera == null or cooldown > 0.0 or ammo <= 0:
		return

	cooldown = fire_rate
	ammo -= 1
	ammo_changed.emit(ammo, reserve_ammo)

	var from: Vector3 = camera.global_position
	var to: Vector3 = from + (-camera.global_transform.basis.z * shot_range)

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player]
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var result: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		print("Shot missed")
		return

	var collider: Object = result.get("collider") as Object
	print("Shot hit: ", collider)

	var damage_target: Object = collider

	if damage_target != null and damage_target.has_method("take_damage"):
		damage_target.call("take_damage", damage)
		print("Zombie hit for ", damage, " damage")
		return

	if collider is Node:
		var node: Node = collider as Node
		var parent: Node = node.get_parent()

		while parent != null:
			if parent.has_method("take_damage"):
				parent.call("take_damage", damage)
				print("Zombie parent hit for ", damage, " damage")
				return
			parent = parent.get_parent()

func reload() -> void:
	if ammo >= magazine_size or reserve_ammo <= 0:
		return

	var needed: int = magazine_size - ammo
	var loaded: int = min(needed, reserve_ammo)
	ammo += loaded
	reserve_ammo -= loaded
	ammo_changed.emit(ammo, reserve_ammo)
