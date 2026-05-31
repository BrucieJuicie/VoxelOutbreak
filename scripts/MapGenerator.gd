extends Node3D

const CELL_SIZE: float = 4.0
const WALL_HEIGHT: float = 3.0
const FLOOR_THICKNESS: float = 0.2
const TEST_GRID: Array[String] = [
	"############",
	"#P.....Z...#",
	"#..##.....Z#",
	"#....#.....#",
	"#..Z....##.#",
	"#......Z...#",
	"############",
]

var player_start: Vector3 = Vector3.ZERO
var zombie_spawns: Array[Vector3] = []
var floor_material: StandardMaterial3D
var wall_material: StandardMaterial3D

func _ready() -> void:
	floor_material = _make_material(Color(0.18, 0.18, 0.17))
	wall_material = _make_material(Color(0.42, 0.40, 0.37))

func build_test_map() -> void:
	if floor_material == null:
		floor_material = _make_material(Color(0.18, 0.18, 0.17))
	if wall_material == null:
		wall_material = _make_material(Color(0.42, 0.40, 0.37))

	_clear_map()
	zombie_spawns.clear()

	for row in TEST_GRID.size():
		var line := TEST_GRID[row]
		for col in line.length():
			var cell := line[col]
			var center := _cell_to_world(row, col)
			if cell == "#":
				_create_box("Wall", center + Vector3(0, WALL_HEIGHT * 0.5, 0), Vector3(CELL_SIZE, WALL_HEIGHT, CELL_SIZE), wall_material, 1)
			else:
				_create_box("Floor", center + Vector3(0, -FLOOR_THICKNESS * 0.5, 0), Vector3(CELL_SIZE, FLOOR_THICKNESS, CELL_SIZE), floor_material, 1)
				if cell == "P":
					player_start = center + Vector3(0, 1.0, 0)
				elif cell == "Z":
					zombie_spawns.append(center + Vector3(0, 0.9, 0))

func get_player_start() -> Vector3:
	return player_start

func get_zombie_spawns() -> Array[Vector3]:
	return zombie_spawns.duplicate()

func _cell_to_world(row: int, col: int) -> Vector3:
	var width := TEST_GRID[0].length()
	var height := TEST_GRID.size()
	var x := (float(col) - float(width - 1) * 0.5) * CELL_SIZE
	var z := (float(row) - float(height - 1) * 0.5) * CELL_SIZE
	return Vector3(x, 0, z)

func _create_box(node_name: String, position: Vector3, size: Vector3, material: Material, collision_layer: int) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = position

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

func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material
