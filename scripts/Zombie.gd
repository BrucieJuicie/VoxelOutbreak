extends CharacterBody3D

signal died(zombie: Node)

@export var max_health: int = 50
@export var speed: float = 2.6
@export var attack_damage: int = 10
@export var attack_range: float = 1.4
@export var attack_cooldown: float = 0.9
@export var points_value: int = 10

var health: int = 50
var player: Node3D
var game_manager: Node
var attack_timer: float = 0.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") as float

func setup(target_player: Node3D, manager: Node) -> void:
	player = target_player
	game_manager = manager

func _ready() -> void:
	health = max_health
	add_to_group("zombies")
	_build_collision()
	_build_sprite()

func _physics_process(delta: float) -> void:
	if player == null:
		return

	attack_timer = max(attack_timer - delta, 0.0)

	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var distance := to_player.length()

	if distance > attack_range:
		var direction := to_player.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		_try_attack()

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	print("Zombie took ", amount, " damage. Health: ", health)

	if health <= 0:
		_die()

func _try_attack() -> void:
	if attack_timer > 0.0 or player == null or not player.has_method("take_damage"):
		return

	attack_timer = attack_cooldown
	player.take_damage(attack_damage)

func _die() -> void:
	if game_manager != null and game_manager.has_method("on_zombie_killed"):
		game_manager.on_zombie_killed(self)
	died.emit(self)
	queue_free()

func _build_collision() -> void:
	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	collision_shape.name = "Hitbox"

	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = 0.55
	shape.height = 2.0

	collision_shape.shape = shape
	collision_shape.position = Vector3(0, 1.0, 0)

	add_child(collision_shape)

func _build_sprite() -> void:
	var sprite := Sprite3D.new()
	sprite.name = "BillboardSprite"
	sprite.texture = _make_placeholder_texture()
	sprite.pixel_size = 0.08
	sprite.position = Vector3(0, 1.0, 0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	add_child(sprite)

func _make_placeholder_texture() -> Texture2D:
	var image := Image.create(32, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	for y in range(8, 43):
		for x in range(8, 24):
			image.set_pixel(x, y, Color(0.18, 0.55, 0.18, 1.0))

	for y in range(3, 16):
		for x in range(10, 22):
			image.set_pixel(x, y, Color(0.32, 0.72, 0.28, 1.0))

	for y in range(7, 10):
		image.set_pixel(13, y, Color(0.9, 0.08, 0.04, 1.0))
		image.set_pixel(19, y, Color(0.9, 0.08, 0.04, 1.0))

	for y in range(18, 31):
		image.set_pixel(5, y, Color(0.14, 0.43, 0.14, 1.0))
		image.set_pixel(26, y, Color(0.14, 0.43, 0.14, 1.0))

	return ImageTexture.create_from_image(image)
