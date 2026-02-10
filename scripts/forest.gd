extends Node2D

# ======================================
# CONFIGURAÇÕES GERAIS DE SPAWN E LOOP
# ======================================
@export var enemy_scene: PackedScene
@export var spawn_interval: float = 4.0
@export var max_enemies: int = 6
@export var kills_for_boss: int = 10
@export var spawn_radius: float = 260.0
@export var min_spawn_distance: float = 140.0

# Multiplicadores básicos de boss (já existiam no projeto).
@export var boss_health_multiplier: float = 3.0
@export var boss_damage_multiplier: float = 2.0
@export var boss_speed_multiplier: float = 1.3

# Chance de drop pedida: 10%.
@export var pickup_drop_chance: float = 0.10

# ======================================
# ESTADO DE PROGRESSÃO
# ======================================
var kill_count: int = 0
var boss_spawned: bool = false
var waiting_boss_characteristic: bool = false
var waiting_upgrade_choice: bool = false
var current_loop: int = 1

# Moeda de reroll (ganha via pickup).
var reroll_count: int = 0

# Característica selecionada para o boss atual.
var selected_boss_characteristic: String = "giant"
const BOSS_CHARACTERISTICS := ["giant", "fast", "ranger"]

# Upgrades simples disponíveis após matar boss.
var upgrade_pool := [
	{"id": "max_health_up", "label": "+20 max HP"},
	{"id": "move_speed_up", "label": "+15% move speed"},
	{"id": "fire_rate_up", "label": "+15% fire rate"},
	{"id": "damage_up", "label": "+20% projectile damage"}
]

# Guardamos 3 opções por tela de upgrade.
var current_upgrade_choices: Array = []

# Cena do pickup carregada por código para não depender do inspector.
var pickup_scene: PackedScene = preload("res://characters/pickup.tscn")

# ======================================
# REFERÊNCIAS DE NÓS
# ======================================
@onready var hero: Node2D = $hero
@onready var spawn_timer: Timer = $SpawnTimer
@onready var progress_bar: ProgressBar = $UI/BossProgress
@onready var boss_label: Label = $UI/BossLabel
@onready var spawn_area: Area2D = $Area2D
@onready var spawn_col: CollisionShape2D = $Area2D/"Spawn - CollisionShape2D"

# Labels extras criadas por script para telas simples (boss/upgrades).
var characteristic_label: Label
var reroll_label: Label
var upgrade_label: Label

func _ready() -> void:
	randomize()
	_setup_progress_ui()
	_setup_overlay_ui()
	_connect_existing_enemies()
	_start_spawn_timer()

func _setup_progress_ui() -> void:
	progress_bar.max_value = kills_for_boss
	progress_bar.value = 0
	boss_label.visible = false

func _setup_overlay_ui() -> void:
	# Tela de "Characteristic + Goblin".
	characteristic_label = Label.new()
	characteristic_label.visible = false
	characteristic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	characteristic_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	characteristic_label.anchors_preset = Control.PRESET_CENTER
	characteristic_label.offset_left = -260
	characteristic_label.offset_top = -70
	characteristic_label.offset_right = 260
	characteristic_label.offset_bottom = 40
	characteristic_label.add_theme_font_size_override("font_size", 26)
	$UI.add_child(characteristic_label)

	reroll_label = Label.new()
	reroll_label.visible = false
	reroll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reroll_label.anchors_preset = Control.PRESET_CENTER
	reroll_label.offset_left = -260
	reroll_label.offset_top = 45
	reroll_label.offset_right = 260
	reroll_label.offset_bottom = 100
	reroll_label.add_theme_font_size_override("font_size", 18)
	$UI.add_child(reroll_label)

	# Tela simples de upgrades pós-boss.
	upgrade_label = Label.new()
	upgrade_label.visible = false
	upgrade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	upgrade_label.anchors_preset = Control.PRESET_CENTER
	upgrade_label.offset_left = -320
	upgrade_label.offset_top = -120
	upgrade_label.offset_right = 320
	upgrade_label.offset_bottom = 140
	upgrade_label.add_theme_font_size_override("font_size", 22)
	$UI.add_child(upgrade_label)

func _connect_existing_enemies() -> void:
	for existing_enemy in get_tree().get_nodes_in_group("enemy"):
		if existing_enemy.has_signal("died"):
			existing_enemy.died.connect(_on_enemy_died)

func _start_spawn_timer() -> void:
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _unhandled_input(event: InputEvent) -> void:
	# Enquanto telas especiais estiverem abertas, bloqueamos fluxo normal.
	if waiting_boss_characteristic:
		_handle_boss_characteristic_input(event)
		return

	if waiting_upgrade_choice:
		_handle_upgrade_input(event)
		return

func _handle_boss_characteristic_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# ENTER confirma spawn do boss com a característica atual.
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			waiting_boss_characteristic = false
			characteristic_label.visible = false
			reroll_label.visible = false
			_spawn_boss()
			get_viewport().set_input_as_handled()
			return

		# R gasta reroll para trocar adjetivo do boss.
		if event.keycode == KEY_R and reroll_count > 0:
			reroll_count -= 1
			_roll_new_characteristic(true)
			_update_characteristic_ui()
			get_viewport().set_input_as_handled()

func _handle_upgrade_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	# Teclas 1,2,3 para escolher upgrade.
	var selected_idx := -1
	if event.keycode == KEY_1:
		selected_idx = 0
	elif event.keycode == KEY_2:
		selected_idx = 1
	elif event.keycode == KEY_3:
		selected_idx = 2

	if selected_idx < 0 or selected_idx >= current_upgrade_choices.size():
		return

	var choice = current_upgrade_choices[selected_idx]
	if hero and hero.has_method("apply_upgrade"):
		hero.apply_upgrade(choice["id"])

	# Fecha tela e reinicia loop do jogo.
	waiting_upgrade_choice = false
	upgrade_label.visible = false
	_restart_game_loop()
	get_viewport().set_input_as_handled()

func _on_spawn_timer_timeout() -> void:
	if boss_spawned or waiting_boss_characteristic or waiting_upgrade_choice:
		return
	if not enemy_scene:
		return
	if get_tree().get_nodes_in_group("enemy").size() >= max_enemies:
		return

	var enemy = enemy_scene.instantiate()
	enemy.global_position = _get_spawn_position()
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	get_tree().current_scene.add_child(enemy)

func _on_enemy_died(enemy: Node, is_boss: bool) -> void:
	# 10% de chance de drop para qualquer inimigo morto.
	_try_drop_pickup(enemy.global_position)

	if is_boss:
		_show_upgrade_screen()
		return

	kill_count += 1
	progress_bar.value = min(kill_count, kills_for_boss)

	# Ao chegar no threshold, abre tela de característica ANTES do boss spawnar.
	if kill_count >= kills_for_boss and not boss_spawned:
		_open_boss_characteristic_screen()

func _try_drop_pickup(at_position: Vector2) -> void:
	if not pickup_scene:
		return
	if randf() > pickup_drop_chance:
		return

	var pickup = pickup_scene.instantiate()
	pickup.global_position = at_position

	# Escolhe entre reroll e cura.
	if randf() < 0.5:
		pickup.pickup_type = "reroll"
	else:
		pickup.pickup_type = "heal"

	get_tree().current_scene.add_child(pickup)

func collect_pickup(pickup_type: String, body: Node) -> void:
	# Método chamado pelo pickup.gd ao ser coletado.
	if pickup_type == "reroll":
		reroll_count += 1
		_update_characteristic_ui()
		return

	if pickup_type == "heal" and body and body.has_method("heal_by_percent"):
		# Cura imediatamente 30% da vida máxima.
		body.heal_by_percent(0.30)

func _open_boss_characteristic_screen() -> void:
	waiting_boss_characteristic = true
	boss_label.visible = true
	spawn_timer.stop()
	_roll_new_characteristic(false)
	_update_characteristic_ui()
	characteristic_label.visible = true
	reroll_label.visible = true

func _roll_new_characteristic(avoid_same: bool) -> void:
	var old := selected_boss_characteristic
	selected_boss_characteristic = BOSS_CHARACTERISTICS[randi() % BOSS_CHARACTERISTICS.size()]
	if avoid_same and BOSS_CHARACTERISTICS.size() > 1:
		while selected_boss_characteristic == old:
			selected_boss_characteristic = BOSS_CHARACTERISTICS[randi() % BOSS_CHARACTERISTICS.size()]

func _update_characteristic_ui() -> void:
	characteristic_label.text = "Characteristic + Goblin\n\n%s goblin\n\nPress ENTER to start" % selected_boss_characteristic
	reroll_label.text = "Rerolls: %d | Press R to reroll adjective" % reroll_count

func _spawn_boss() -> void:
	boss_spawned = true
	if not enemy_scene:
		return

	var boss = enemy_scene.instantiate()
	boss.global_position = _get_spawn_position()

	if "is_boss" in boss:
		boss.is_boss = true

	# Primeiro aplica característica temática escolhida pelo jogador.
	if boss.has_method("configure_as_boss"):
		boss.configure_as_boss(selected_boss_characteristic)

	# Depois aplica multiplicadores gerais de boss da fase.
	if "health" in boss:
		boss.health = int(boss.health * boss_health_multiplier)
	if "damage" in boss:
		boss.damage = int(boss.damage * boss_damage_multiplier)
	if "speed" in boss:
		boss.speed *= boss_speed_multiplier

	# Caso não tenha recebido scale por característica, aplica escala padrão.
	if boss.scale == Vector2.ONE:
		boss.scale = Vector2(1.4, 1.4)

	if boss.has_signal("died"):
		boss.died.connect(_on_enemy_died)

	get_tree().current_scene.add_child(boss)
	boss_label.text = "boss active"

func _show_upgrade_screen() -> void:
	waiting_upgrade_choice = true
	boss_label.text = "boss defeated"
	current_upgrade_choices.clear()

	# Monta 3 opções aleatórias simples.
	var local_pool := upgrade_pool.duplicate(true)
	local_pool.shuffle()
	for i in range(min(3, local_pool.size())):
		current_upgrade_choices.append(local_pool[i])

	var text := "Choose an upgrade\n\n"
	for i in range(current_upgrade_choices.size()):
		text += "%d) %s\n" % [i + 1, current_upgrade_choices[i]["label"]]
	text += "\nPress 1, 2 or 3"

	upgrade_label.text = text
	upgrade_label.visible = true

func _restart_game_loop() -> void:
	# Reinicia ciclo após matar boss + escolher upgrade.
	current_loop += 1
	kill_count = 0
	boss_spawned = false
	waiting_boss_characteristic = false
	progress_bar.value = 0
	boss_label.text = ""
	boss_label.visible = false

	# Limpa restos de entidades do loop anterior.
	_clear_group_nodes("enemy")
	_clear_projectiles_and_pickups()

	# Recomeça spawn normal.
	spawn_timer.start()

func _clear_group_nodes(group_name: String) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		if is_instance_valid(node):
			node.queue_free()

func _clear_projectiles_and_pickups() -> void:
	for node in get_tree().current_scene.get_children():
		if not is_instance_valid(node):
			continue
		# Remove projéteis pela presença de propriedade "team".
		if "team" in node:
			node.queue_free()
		# Remove pickups pelo script específico.
		if node.has_method("get_script") and node.get_script() and str(node.get_script()).find("pickup.gd") != -1:
			node.queue_free()

func _get_spawn_position() -> Vector2:
	var origin := hero.global_position if hero else Vector2.ZERO

	for _i in range(30):
		var p := _random_point_in_spawn_area()
		if p.distance_to(origin) >= min_spawn_distance:
			return p

	var fallback := _random_point_in_spawn_area()
	if fallback != Vector2.INF:
		return fallback

	for _i in range(12):
		var offset := Vector2(
			randf_range(-spawn_radius, spawn_radius),
			randf_range(-spawn_radius, spawn_radius)
		)
		if offset.length() >= min_spawn_distance:
			return origin + offset
	return origin + Vector2(spawn_radius, 0)

func _random_point_in_spawn_area() -> Vector2:
	if not is_instance_valid(spawn_col) or spawn_col.shape == null:
		return Vector2.INF

	var shape: Shape2D = spawn_col.shape
	var t: Transform2D = spawn_col.global_transform

	if shape is RectangleShape2D:
		var rect := shape as RectangleShape2D
		var ext: Vector2 = rect.size * 0.5
		var local := Vector2(
			randf_range(-ext.x, ext.x),
			randf_range(-ext.y, ext.y)
		)
		return t * local

	if shape is CircleShape2D:
		var circle := shape as CircleShape2D
		var r: float = circle.radius
		var ang: float = randf() * TAU
		var rad: float = sqrt(randf()) * r
		var local: Vector2 = Vector2(cos(ang), sin(ang)) * rad
		return t * local

	return spawn_area.global_position
