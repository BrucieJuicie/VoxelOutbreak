extends Node3D

const BuyableDoorScript = preload("res://scripts/BuyableDoor.gd")
const PickupScript = preload("res://scripts/Pickup.gd")

const CELL_SIZE: float = 4.0
const WALL_HEIGHT: float = 3.0
const FLOOR_THICKNESS: float = 0.2
const TEST_GRID: Array[String] = [
	"#########################",
	"#...Z.....L.....Z.......#",
	"#..C......L......C......#",
	"#.......................#",
	"############2############",
	"#..#A...Z#.....#H.Z.C#..#",
	"#..#..L..#.....#..L..#..#",
	"#..#.....#.....#.....#..#",
	"#..###1###..C..###1###..#",
	"#..Z.B...Z...Z.....B.Z..#",
	"#..T..C..Z..O..Z..C..T..#",
	"#.........P.............#",
	"#########################",
]

var player_start: Vector3 = Vector3.ZERO
var zombie_spawn_records: Array[Dictionary] = []
var unlocked_spawn_gates: Array[String] = [""]
var floor_material: StandardMaterial3D
var wall_material: StandardMaterial3D
var crate_material: StandardMaterial3D
var pallet_material: StandardMaterial3D
var pillar_material: StandardMaterial3D
var shelf_material: StandardMaterial3D
var barrel_material: StandardMaterial3D
var barricade_material: StandardMaterial3D

func _ready() -> void:
	_ensure_materials()

func build_test_map(game_manager: Node = null) -> void:
	_ensure_materials()
	_clear_map()
	zombie_spawn_records.clear()
	unlocked_spawn_gates = [""]

	for row in TEST_GRID.size():
		var line := TEST_GRID[row]
		for col in line.length():
			var cell := line[col]
			var center := _cell_to_world(row, col)
			if cell == "#":
				_create_box("Wall", center + Vector3(0, WALL_HEIGHT * 0.5, 0), Vector3(CELL_SIZE, WALL_HEIGHT, CELL_SIZE), wall_material, 1)
			else:
				_create_box("Floor", center + Vector3(0, -FLOOR_THICKNESS * 0.5, 0), Vector3(CELL_SIZE, FLOOR_THICKNESS, CELL_SIZE), floor_material, 1)
				_handle_floor_marker(cell, row, col, center, game_manager)

func get_player_start() -> Vector3:
	return player_start

func get_zombie_spawns() -> Array[Vector3]:
	var active_spawns: Array[Vector3] = []

	for record in zombie_spawn_records:
		var gate: String = record["gate"] as String
		if unlocked_spawn_gates.has(gate):
			active_spawns.append(record["position"] as Vector3)

	return active_spawns

func unlock_spawn_gate(gate: String) -> void:
	if gate.is_empty() or unlocked_spawn_gates.has(gate):
		return

	unlocked_spawn_gates.append(gate)

func get_path_world_points(from_position: Vector3, to_position: Vector3) -> Array[Vector3]:
	var start_cell: Vector2i = _nearest_walkable_cell(_world_to_cell(from_position))
	var goal_cell: Vector2i = _nearest_walkable_cell(_world_to_cell(to_position))
	var cell_path: Array[Vector2i] = _find_grid_path(start_cell, goal_cell)
	var world_path: Array[Vector3] = []

	for path_index in range(1, cell_path.size()):
		var cell: Vector2i = cell_path[path_index]
		world_path.append(_cell_to_world(cell.y, cell.x) + Vector3(0, 0.1, 0))

	return world_path

func _cell_to_world(row: int, col: int) -> Vector3:
	var width: int = TEST_GRID[0].length()
	var height: int = TEST_GRID.size()
	var x: float = (float(col) - float(width - 1) * 0.5) * CELL_SIZE
	var z: float = (float(row) - float(height - 1) * 0.5) * CELL_SIZE
	return Vector3(x, 0, z)

func _handle_floor_marker(cell: String, row: int, col: int, center: Vector3, game_manager: Node) -> void:
	if cell == "P":
		player_start = center + Vector3(0, 1.0, 0)
	elif cell == "Z":
		zombie_spawn_records.append({
			"position": center + Vector3(0, 0.1, 0),
			"gate": _spawn_gate_for_cell(row, col),
		})
	elif cell == "1" or cell == "2":
		_create_buyable_door(cell, col, center)
	elif cell == "A":
		_create_pickup("ammo", center, game_manager)
	elif cell == "H":
		_create_pickup("health", center, game_manager)
	elif cell == "C":
		_create_crate(center)
	elif cell == "T":
		_create_pallet(center)
	elif cell == "O":
		_create_pillar(center)
	elif cell == "L":
		_create_shelf(center)
	elif cell == "B":
		_create_barrel(center)

func _spawn_gate_for_cell(row: int, col: int) -> String:
	var center_col: int = int(float(TEST_GRID[0].length()) * 0.5)

	if row <= 3:
		return "back_area"
	if row >= 5 and row <= 7 and col < center_col:
		return "left_storage"
	if row >= 5 and row <= 7 and col > center_col:
		return "right_medbay"

	return ""

func _create_buyable_door(cell: String, col: int, center: Vector3) -> void:
	var door: StaticBody3D = BuyableDoorScript.new() as StaticBody3D
	var label: String = "Barricade"
	var cost: int = 30
	var gate: String = "left_storage"
	var color: Color = Color(0.45, 0.26, 0.12)

	if cell == "2":
		label = "Back warehouse gate"
		cost = 70
		color = Color(0.42, 0.42, 0.38)
	elif col > _center_column():
		label = "Med bay shutter"
		cost = 40
	else:
		label = "Storage barricade"
		cost = 30

	gate = _door_gate_for_cell(cell, col)

	door.name = label.replace(" ", "")
	door.position = center + Vector3(0, 1.15, 0)
	add_child(door)
	door.call("setup", label, cost, gate, Vector3(CELL_SIZE * 0.95, 2.3, 0.45), color)

func _create_pickup(kind: String, center: Vector3, game_manager: Node) -> void:
	var pickup: Area3D = PickupScript.new() as Area3D
	pickup.name = "%sPickup" % kind.capitalize()
	pickup.position = center + Vector3(0, 0.55, 0)
	pickup.call("setup", kind, 25, game_manager)
	add_child(pickup)

func _create_crate(center: Vector3) -> void:
	_create_box("Crate", center + Vector3(0, 0.65, 0), Vector3(1.8, 1.3, 1.8), crate_material, 1)

func _create_pallet(center: Vector3) -> void:
	_create_box("Pallet", center + Vector3(0, 0.15, 0), Vector3(2.6, 0.3, 1.6), pallet_material, 1)

func _create_pillar(center: Vector3) -> void:
	_create_box("Pillar", center + Vector3(0, 1.5, 0), Vector3(1.2, 3.0, 1.2), pillar_material, 1)

func _create_shelf(center: Vector3) -> void:
	_create_box("Shelf", center + Vector3(0, 1.0, 0), Vector3(0.65, 2.0, 2.9), shelf_material, 1)

func _create_barrel(center: Vector3) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Barrel"
	mesh_instance.position = center + Vector3(0, 0.6, 0)

	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.55
	mesh.bottom_radius = 0.55
	mesh.height = 1.2
	mesh.material = barrel_material
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

	var static_body := StaticBody3D.new()
	static_body.collision_layer = 1
	mesh_instance.add_child(static_body)

	var collision_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.1, 1.2, 1.1)
	collision_shape.shape = shape
	static_body.add_child(collision_shape)

func _create_box(node_name: String, box_position: Vector3, size: Vector3, material: Material, collision_layer: int) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = box_position

	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

	var static_body := StaticBody3D.new()
	static_body.collision_layer = collision_layer
	mesh_instance.add_child(static_body)

	var collision_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision_shape.shape = shape
	static_body.add_child(collision_shape)

func _clear_map() -> void:
	for child in get_children():
		child.queue_free()

func _world_to_cell(world_position: Vector3) -> Vector2i:
	var width: int = TEST_GRID[0].length()
	var height: int = TEST_GRID.size()
	var col: int = int(round((world_position.x / CELL_SIZE) + float(width - 1) * 0.5))
	var row: int = int(round((world_position.z / CELL_SIZE) + float(height - 1) * 0.5))
	return Vector2i(col, row)

func _nearest_walkable_cell(cell: Vector2i) -> Vector2i:
	if _is_cell_walkable(cell):
		return cell

	for radius in range(1, 6):
		for y_offset in range(-radius, radius + 1):
			for x_offset in range(-radius, radius + 1):
				var candidate := Vector2i(cell.x + x_offset, cell.y + y_offset)
				if _is_cell_walkable(candidate):
					return candidate

	return cell

func _find_grid_path(start_cell: Vector2i, goal_cell: Vector2i) -> Array[Vector2i]:
	var frontier: Array[Vector2i] = [start_cell]
	var came_from: Dictionary = {}
	came_from[start_cell] = start_cell

	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == goal_cell:
			break

		for neighbor in _get_walkable_neighbors(current):
			if came_from.has(neighbor):
				continue

			frontier.append(neighbor)
			came_from[neighbor] = current

	if not came_from.has(goal_cell):
		return []

	var path: Array[Vector2i] = [goal_cell]
	var step: Vector2i = goal_cell

	while step != start_cell:
		step = came_from[step] as Vector2i
		path.push_front(step)

	return path

func _get_walkable_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
	]

	for direction in directions:
		var candidate := cell + direction
		if _is_cell_walkable(candidate):
			neighbors.append(candidate)

	return neighbors

func _is_cell_walkable(cell: Vector2i) -> bool:
	if cell.y < 0 or cell.y >= TEST_GRID.size():
		return false
	if cell.x < 0 or cell.x >= TEST_GRID[cell.y].length():
		return false

	var marker: String = TEST_GRID[cell.y][cell.x]
	if marker == "#":
		return false
	if marker == "C" or marker == "T" or marker == "O" or marker == "L" or marker == "B":
		return false
	if marker == "1" or marker == "2":
		return unlocked_spawn_gates.has(_door_gate_for_cell(marker, cell.x))

	return true

func _door_gate_for_cell(cell: String, col: int) -> String:
	if cell == "2":
		return "back_area"
	if col > _center_column():
		return "right_medbay"
	return "left_storage"

func _center_column() -> int:
	return int(float(TEST_GRID[0].length()) * 0.5)

func _ensure_materials() -> void:
	if floor_material != null:
		return

	floor_material = _make_material(Color(0.18, 0.18, 0.17))
	wall_material = _make_material(Color(0.42, 0.40, 0.37))
	crate_material = _make_material(Color(0.42, 0.27, 0.13))
	pallet_material = _make_material(Color(0.33, 0.22, 0.12))
	pillar_material = _make_material(Color(0.32, 0.34, 0.34))
	shelf_material = _make_material(Color(0.18, 0.23, 0.26))
	barrel_material = _make_material(Color(0.22, 0.31, 0.46))
	barricade_material = _make_material(Color(0.45, 0.26, 0.12))

func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material
