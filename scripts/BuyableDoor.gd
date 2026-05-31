extends StaticBody3D

var display_name: String = "Door"
var cost: int = 30
var spawn_gate: String = ""
var is_open: bool = false
var blocker_mesh: MeshInstance3D
var blocker_collision: CollisionShape3D

func setup(label: String, price: int, gate: String, size: Vector3, color: Color) -> void:
	display_name = label
	cost = price
	spawn_gate = gate
	add_to_group("buyable_doors")
	_build_blocker(size, color)

func get_prompt(points: int) -> String:
	if is_open:
		return ""
	if points >= cost:
		return "Open %s (%d points) (E)" % [display_name, cost]
	return "%s costs %d points (E)" % [display_name, cost]

func interact(game_manager: Node) -> bool:
	if is_open:
		return false
	if game_manager == null or not game_manager.has_method("spend_points"):
		return false

	var did_spend: bool = game_manager.call("spend_points", cost) as bool
	if not did_spend:
		return false

	open()
	return true

func open() -> void:
	is_open = true
	remove_from_group("buyable_doors")
	visible = false
	if blocker_mesh != null:
		blocker_mesh.visible = false
	if blocker_collision != null:
		blocker_collision.disabled = true

func _build_blocker(size: Vector3, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0

	blocker_mesh = MeshInstance3D.new()
	blocker_mesh.name = "BlockerMesh"
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	blocker_mesh.mesh = mesh
	add_child(blocker_mesh)

	blocker_collision = CollisionShape3D.new()
	blocker_collision.name = "BlockerCollision"
	var shape := BoxShape3D.new()
	shape.size = size
	blocker_collision.shape = shape
	add_child(blocker_collision)
