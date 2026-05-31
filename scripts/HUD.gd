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
var prompt_label: Label

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

	_add_crosshair(root)

	prompt_label = _make_label()
	prompt_label.text = ""
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.anchor_left = 0.2
	prompt_label.anchor_top = 1.0
	prompt_label.anchor_right = 0.8
	prompt_label.anchor_bottom = 1.0
	prompt_label.offset_left = 0
	prompt_label.offset_top = -74
	prompt_label.offset_right = 0
	prompt_label.offset_bottom = -34
	root.add_child(prompt_label)

func _make_label() -> Label:
	var label := Label.new()
	label.add_theme_color_override("font_color", Color(0.94, 0.96, 0.86))
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_font_size_override("font_size", 20)
	return label

func _add_crosshair(root: Control) -> void:
	_add_crosshair_bar(root, Vector2(-18, -1), Vector2(11, 2))
	_add_crosshair_bar(root, Vector2(7, -1), Vector2(11, 2))
	_add_crosshair_bar(root, Vector2(-1, -18), Vector2(2, 11))
	_add_crosshair_bar(root, Vector2(-1, 7), Vector2(2, 11))

func _add_crosshair_bar(root: Control, bar_offset: Vector2, size: Vector2) -> void:
	var bar := ColorRect.new()
	bar.color = Color(0.94, 0.96, 0.86, 0.92)
	bar.anchor_left = 0.5
	bar.anchor_top = 0.5
	bar.anchor_right = 0.5
	bar.anchor_bottom = 0.5
	bar.offset_left = bar_offset.x
	bar.offset_top = bar_offset.y
	bar.offset_right = bar_offset.x + size.x
	bar.offset_bottom = bar_offset.y + size.y
	root.add_child(bar)

func refresh() -> void:
	if game_manager == null or player == null or weapon_manager == null or wave_manager == null:
		return

	health_label.text = "Health: %d" % int(player.get("health"))
	ammo_label.text = "Ammo: %d / %d" % [int(weapon_manager.get("ammo")), int(weapon_manager.get("reserve_ammo"))]
	wave_label.text = "Wave: %d" % int(wave_manager.get("current_wave"))
	points_label.text = "Points: %d" % int(game_manager.get("points"))
	zombies_label.text = "Zombies: %d" % int(wave_manager.call("get_zombies_remaining"))

func set_prompt(text: String) -> void:
	if prompt_label != null:
		prompt_label.text = text
