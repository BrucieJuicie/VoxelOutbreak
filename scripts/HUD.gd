extends CanvasLayer

var game_manager: Node
var player: Node
var weapon_manager: Node
var wave_manager: Node

var health_label: Label
var ammo_label: Label
var wave_label: Label
var points_label: Label
var zombies_label: Label

func setup(manager: Node, player_node: Node, weapon_node: Node, wave_node: Node) -> void:
	game_manager = manager
	player = player_node
	weapon_manager = weapon_node
	wave_manager = wave_node
	_build_ui()
	refresh()

func _process(_delta: float) -> void:
	refresh()

func _build_ui() -> void:
	var root := Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	add_child(root)

	var stats := VBoxContainer.new()
	stats.position = Vector2(18, 18)
	stats.add_theme_constant_override("separation", 4)
	root.add_child(stats)

	health_label = _make_label()
	ammo_label = _make_label()
	wave_label = _make_label()
	points_label = _make_label()
	zombies_label = _make_label()

	stats.add_child(health_label)
	stats.add_child(ammo_label)
	stats.add_child(wave_label)
	stats.add_child(points_label)
	stats.add_child(zombies_label)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -12
	crosshair.offset_top = -12
	crosshair.offset_right = 12
	crosshair.offset_bottom = 12
	crosshair.add_theme_font_size_override("font_size", 24)
	root.add_child(crosshair)

func _make_label() -> Label:
	var label := Label.new()
	label.add_theme_color_override("font_color", Color(0.94, 0.96, 0.86))
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_font_size_override("font_size", 20)
	return label

func refresh() -> void:
	if game_manager == null or player == null or weapon_manager == null or wave_manager == null:
		return

	health_label.text = "Health: %d" % int(player.get("health"))
	ammo_label.text = "Ammo: %d / %d" % [int(weapon_manager.get("ammo")), int(weapon_manager.get("reserve_ammo"))]
	wave_label.text = "Wave: %d" % int(wave_manager.get("current_wave"))
	points_label.text = "Points: %d" % int(game_manager.get("points"))
	zombies_label.text = "Zombies: %d" % int(wave_manager.call("get_zombies_remaining"))
