extends Area3D

var pickup_type: String = "ammo"
var amount: int = 25
var game_manager: Node
var consumed: bool = false

func setup(kind: String, pickup_amount: int, manager: Node) -> void:
	pickup_type = kind
	amount = pickup_amount
	game_manager = manager

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_build_visual()

func _process(delta: float) -> void:
	rotate_y(delta * 1.7)

func _on_body_entered(body: Node3D) -> void:
	if consumed or game_manager == null:
		return

	var player: Node = game_manager.get("player") as Node
	if body != player:
		return

	var did_consume: bool = false
	if pickup_type == "health" and body.has_method("heal"):
		did_consume = body.call("heal", amount) as bool
	elif pickup_type == "ammo":
		var weapon_manager: Node = game_manager.get("weapon_manager") as Node
		if weapon_manager != null and weapon_manager.has_method("add_reserve_ammo"):
			did_consume = weapon_manager.call("add_reserve_ammo", amount) as bool

	if did_consume:
		consumed = true
		queue_free()

func _build_visual() -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "PickupMesh"

	var material := StandardMaterial3D.new()
	material.roughness = 0.7

	if pickup_type == "health":
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.9, 0.45, 0.9)
		material.albedo_color = Color(0.82, 0.1, 0.1)
		mesh.material = material
		mesh_instance.mesh = mesh
	else:
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.0, 0.35, 0.65)
		material.albedo_color = Color(0.9, 0.78, 0.18)
		mesh.material = material
		mesh_instance.mesh = mesh

	add_child(mesh_instance)

	var collision_shape := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.85
	collision_shape.shape = shape
	add_child(collision_shape)
