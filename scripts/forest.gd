extends Node2D

@export var enemy_scene: PackedScene
@export var pickup_scene: PackedScene
@export var spawn_interval: float = 4.0
@export var max_enemies: int = 6
@export var kills_for_boss: int = 10
@export var spawn_radius: float = 260.0
@export var min_spawn_distance: float = 140.0
@export var boss_health_multiplier: float = 3.0
@export var boss_damage_multiplier: float = 2.0
@export var boss_speed_multiplier: float = 1.3

# Probabilidade de drop por inimigo comum
const PICKUP_DROP_CHANCE: float = 0.10

# Traits disponíveis para o boss
const BOSS_TRAITS := ["giant", "fast", "ranger"]

# Controle de fase
var kill_count: int = 0
var boss_spawned: bool = false
var waiting_boss_confirmation: bool = false
var waiting_upgrade_selection: bool = false
var selected_boss_trait: String = "giant"

# Referências principais
@onready var hero: Node2D = $hero
@onready var spawn_timer: Timer = $SpawnTimer
@onready var progress_bar: ProgressBar = $UI/BossProgress
@onready var boss_label: Label = $UI/BossLabel

# Área de spawn
@onready var spawn_area: Area2D = $Area2D
@onready var spawn_col: CollisionShape2D = $Area2D/"Spawn - CollisionShape2D"

# UI dinâmica
var overlay_panel: Panel = null
var overlay_label: Label = null
var overlay_hint: Label = null
var reroll_label: Label = null

func _ready() -> void:
	randomize()
	_setup_ui_overlay()

	# Inicializa barra de progresso do boss
	progress_bar.max_value = kills_for_boss
	progress_bar.value = 0
	boss_label.visible = false

	# Conecta inimigos já existentes, se houver
	for existing_enemy in get_tree().get_nodes_in_group("enemy"):
		if existing_enemy.has_signal("died"):
			existing_enemy.died.connect(_on_enemy_died)

	# Inicializa timer de spawn
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _process(_delta: float) -> void:
	# Atualiza contador de reroll na UI
	_update_reroll_ui()

func _unhandled_input(event: InputEvent) -> void:
	# Captura inputs apenas no momento do toque da tecla (sem repetir em loop)
	if not (event is InputEventKey):
		return
	
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	# Input da tela pré-boss
	if waiting_boss_confirmation:
		if key_event.keycode == KEY_ENTER:
			_begin_boss_fight()
		elif key_event.keycode == KEY_R:
			_try_reroll_boss_trait()
		return

	# Input da tela de upgrade
	if waiting_upgrade_selection:
		match key_event.keycode:
			KEY_1:
				_apply_upgrade_max_health()
				_reset_run_loop()
			KEY_2:
				_apply_upgrade_move_speed()
				_reset_run_loop()
			KEY_3:
				_apply_upgrade_firepower()
				_reset_run_loop()

func _setup_ui_overlay() -> void:
	# Cria um painel de overlay simples e reutilizável para telas intermediárias
	overlay_panel = Panel.new()
	overlay_panel.visible = false
	overlay_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	$UI.add_child(overlay_panel)

	overlay_label = Label.new()
	overlay_label.set_anchors_preset(Control.PRESET_CENTER)
	overlay_label.offset_left = -220
	overlay_label.offset_top = -70
	overlay_label.offset_right = 220
	overlay_label.offset_bottom = -30
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_label.add_theme_font_size_override("font_size", 30)
	overlay_panel.add_child(overlay_label)

	overlay_hint = Label.new()
	overlay_hint.set_anchors_preset(Control.PRESET_CENTER)
	overlay_hint.offset_left = -260
	overlay_hint.offset_top = -10
	overlay_hint.offset_right = 260
	overlay_hint.offset_bottom = 40
	overlay_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_panel.add_child(overlay_hint)

	reroll_label = Label.new()
	reroll_label.anchors_preset = Control.PRESET_TOP_RIGHT
	reroll_label.offset_left = -220
	reroll_label.offset_top = 12
	reroll_label.offset_right = -16
	reroll_label.offset_bottom = 42
	reroll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	$UI.add_child(reroll_label)

func _on_spawn_timer_timeout() -> void:
	# Não spawna inimigos durante estados especiais
	if boss_spawned or waiting_boss_confirmation or waiting_upgrade_selection:
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

func _get_spawn_position() -> Vector2:
	var origin := hero.global_position if hero else Vector2.ZERO

	# Tenta achar ponto na área com distância mínima do herói
	for _i in range(30):
		var p := _random_point_in_spawn_area()
		if p.distance_to(origin) >= min_spawn_distance:
			return p

	# Fallback para qualquer ponto da área
	var fallback := _random_point_in_spawn_area()
	if fallback != Vector2.INF:
		return fallback

	# Fallback final por raio
	for _i in range(12):
		var offset := Vector2(
			randf_range(-spawn_radius, spawn_radius),
			randf_range(-spawn_radius, spawn_radius)
		)
		if offset.length() >= min_spawn_distance:
			return origin + offset
	return origin + Vector2(spawn_radius, 0)

func _random_point_in_spawn_area() -> Vector2:
	# Se não existir shape de spawn, sinaliza inválido
	if not is_instance_valid(spawn_col) or spawn_col.shape == null:
		return Vector2.INF

	var shape: Shape2D = spawn_col.shape
	var t: Transform2D = spawn_col.global_transform

	if shape is RectangleShape2D:
		var rect := shape as RectangleShape2D
		var ext: Vector2 = rect.size * 0.5
		var local: Vector2 = Vector2(
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

func _on_enemy_died(enemy: Node, is_boss: bool) -> void:
	# Se for boss, abre tela de upgrade
	if is_boss:
		_on_boss_defeated()
		return

	# Chance de 10% de drop em inimigos comuns
	_try_spawn_pickup(enemy.global_position)

	# Atualiza progresso para boss
	kill_count += 1
	progress_bar.value = min(kill_count, kills_for_boss)

	# Mostra tela de característica antes do boss aparecer
	if kill_count >= kills_for_boss and not boss_spawned and not waiting_boss_confirmation:
		_show_boss_intro_screen()

func _try_spawn_pickup(position: Vector2) -> void:
	# Sem cena configurada, não gera drop
	if not pickup_scene:
		return

	# Chance de drop de 10%
	if randf() > PICKUP_DROP_CHANCE:
		return

	# Sorteia pickup entre reroll e cura
	var pickup = pickup_scene.instantiate()
	pickup.global_position = position
	if "pickup_type" in pickup:
		pickup.pickup_type = "reroll" if randf() < 0.5 else "heal"
	get_tree().current_scene.add_child(pickup)

func _show_boss_intro_screen() -> void:
	# Entra em estado de pré-boss
	waiting_boss_confirmation = true
	spawn_timer.stop()

	# Sorteia adjetivo inicial do boss
	selected_boss_trait = BOSS_TRAITS[randi() % BOSS_TRAITS.size()]

	# Mostra tela "characteristic + goblin"
	overlay_panel.visible = true
	overlay_label.text = "%s goblin" % selected_boss_trait
	overlay_hint.text = "ENTER = start fight | R = reroll trait (cost: 1 reroll)"
	boss_label.visible = true

func _try_reroll_boss_trait() -> void:
	# Só rerolla se o herói tiver carga de reroll
	if hero and hero.has_method("consume_reroll") and hero.consume_reroll():
		selected_boss_trait = BOSS_TRAITS[randi() % BOSS_TRAITS.size()]
		overlay_label.text = "%s goblin" % selected_boss_trait

func _begin_boss_fight() -> void:
	# Sai da tela e inicia luta
	waiting_boss_confirmation = false
	overlay_panel.visible = false
	_spawn_boss(selected_boss_trait)

func _spawn_boss(trait_name: String) -> void:
	boss_spawned = true
	if not enemy_scene:
		return

	var boss = enemy_scene.instantiate()
	boss.global_position = _get_spawn_position()

	# Aplica stats base de boss
	if "is_boss" in boss:
		boss.is_boss = true
	if "health" in boss:
		boss.health = int(boss.health * boss_health_multiplier)
	if "damage" in boss:
		boss.damage = int(boss.damage * boss_damage_multiplier)
	if "speed" in boss:
		boss.speed = boss.speed * boss_speed_multiplier

	# Aplica traço do adjetivo sorteado
	if boss.has_method("configure_boss_trait"):
		boss.configure_boss_trait(trait_name)

	if boss.has_signal("died"):
		boss.died.connect(_on_enemy_died)

	get_tree().current_scene.add_child(boss)

func _on_boss_defeated() -> void:
	# Abre tela simples de upgrades após matar o boss
	waiting_upgrade_selection = true
	overlay_panel.visible = true
	overlay_label.text = "Choose your upgrade"
	overlay_hint.text = "1) +20 max HP\n2) +15% move speed\n3) +20% fire rate +5 projectile damage"

func _apply_upgrade_max_health() -> void:
	# Upgrade de sobrevivência
	if hero and "max_health" in hero and "current_health" in hero:
		hero.max_health += 20
		hero.current_health = min(hero.max_health, hero.current_health + 20)

func _apply_upgrade_move_speed() -> void:
	# Upgrade de mobilidade
	if hero and "move_speed" in hero:
		hero.move_speed *= 1.15

func _apply_upgrade_firepower() -> void:
	# Upgrade ofensivo simples
	if hero and "fire_cooldown" in hero:
		hero.fire_cooldown *= 0.80
	if hero and "bonus_projectile_damage" in hero:
		hero.bonus_projectile_damage += 5

func _reset_run_loop() -> void:
	# Reinicia o ciclo completo após escolher upgrade
	waiting_upgrade_selection = false
	overlay_panel.visible = false

	kill_count = 0
	boss_spawned = false
	progress_bar.value = 0
	boss_label.visible = false

	# Remove inimigos e pickups remanescentes
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.queue_free()
	for pickup in get_tree().get_nodes_in_group("pickup"):
		pickup.queue_free()

	# Reativa o spawn normal
	spawn_timer.start()

func _update_reroll_ui() -> void:
	# Exibe contador de rerolls do jogador
	if hero and "reroll_count" in hero:
		reroll_label.text = "Reroll: %d" % hero.reroll_count
	else:
		reroll_label.text = "Reroll: 0"
