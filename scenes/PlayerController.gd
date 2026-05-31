extends CharacterBody3D

signal health_changed(health: int, max_health: int)
signal died

@export var walk_speed: float = 6.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 5.0
@export var mouse_sensitivity: float = 0.002
@export var max_health: int = 100

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") as float
var pitch: float = 0.0
var health: int = 100

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	health = max_health
	camera.position.y = 0.68
	_build_view_model()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	health_changed.emit(health, max_health)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rotation.y -= event.relative.x * mouse_sensitivity
			pitch -= event.relative.y * mouse_sensitivity
			pitch = clamp(pitch, deg_to_rad(-85), deg_to_rad(85))
			camera.rotation.x = pitch

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	var input_dir: Vector2 = Vector2.ZERO

	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1

	input_dir = input_dir.normalized()

	var speed: float = walk_speed
	if Input.is_key_pressed(KEY_SHIFT):
		speed = sprint_speed

	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

func take_damage(amount: int) -> void:
	if health <= 0:
		return

	health = max(health - amount, 0)
	health_changed.emit(health, max_health)

	if health == 0:
		died.emit()

func heal(amount: int) -> bool:
	if health <= 0 or health >= max_health:
		return false

	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)
	return true

func _build_view_model() -> void:
	if camera.has_node("PistolViewModel"):
		return

	var holder := Node3D.new()
	holder.name = "PistolViewModel"
	holder.position = Vector3(0.34, -0.28, -0.72)
	holder.rotation_degrees = Vector3(-3.0, -7.0, 0.0)
	camera.add_child(holder)

	var body_material := _make_view_model_material(Color(0.08, 0.08, 0.075))
	var grip_material := _make_view_model_material(Color(0.16, 0.11, 0.08))
	var accent_material := _make_view_model_material(Color(0.36, 0.36, 0.34))

	_add_view_model_box(holder, "Slide", Vector3(0.32, 0.13, 0.62), Vector3(0.0, 0.04, -0.08), body_material)
	_add_view_model_box(holder, "Grip", Vector3(0.2, 0.34, 0.18), Vector3(0.0, -0.16, 0.11), grip_material)
	_add_view_model_box(holder, "Barrel", Vector3(0.13, 0.09, 0.38), Vector3(0.0, 0.045, -0.46), accent_material)

func _add_view_model_box(parent: Node3D, node_name: String, size: Vector3, local_position: Vector3, material: Material) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = local_position

	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	mesh_instance.mesh = mesh
	parent.add_child(mesh_instance)

func _make_view_model_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.55
	return material
