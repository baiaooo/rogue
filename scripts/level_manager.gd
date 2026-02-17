class_name LevelManager
extends Node2D

# =========================
# DADOS DA FASE (RESOURCE)
# =========================
@export var level_data: LevelData

# =========================
# CONFIGURAÇÕES ÚNICAS DA INSTÂNCIA
# =========================
@export var enemy_scenes: Array[PackedScene] = []
@export var spawn_interval: float = 4.0
@export var max_enemies: int = 6
@export var kills_for_boss: int = 10
@export var spawn_radius: float = 260.0
@export var min_spawn_distance: float = 140.0
@export var boss_health_multiplier: float = 3.0
@export var boss_damage_multiplier: float = 2.0
@export var boss_speed_multiplier: float = 1.3
@export var upgrade_screen_scene: PackedScene
@export var flag_scene: PackedScene  # Cena da bandeira
@export var hero_scene: PackedScene  # Cena do herói

# =========================
# VARIÁVEIS INTERNAS
# =========================
var kill_count: int = 0
var boss_spawned: bool = false
var flag_spawned: bool = false
var upgrade_screen: CanvasLayer = null
var hero: Node2D = null

var spawn_timer: Timer = null
var progress_bar: ProgressBar = null
var boss_label: Label = null
var stage_label: Label = null
var spawn_area: Area2D = null
var spawn_col: CollisionShape2D = null
var hero_spawn_point: Marker2D = null


func _ready() -> void:
	_cache_scene_nodes()
	randomize()
	
	# Spawna o herói
	_spawn_hero()
	
	# Marca avanço da fase atual
	var current_level_number = GameGlobals.advance_level_counter()
	
	# Carrega dados do resource se disponível
	if level_data:
		if not enemy_scenes.is_empty():
			enemy_scenes = level_data.enemy_scenes
		spawn_interval = level_data.spawn_interval
		max_enemies = level_data.max_enemies
		kills_for_boss = level_data.kills_for_boss
		spawn_radius = level_data.spawn_radius
		min_spawn_distance = level_data.min_spawn_distance
		boss_health_multiplier = level_data.boss_health_multiplier
		boss_damage_multiplier = level_data.boss_damage_multiplier
		boss_speed_multiplier = level_data.boss_speed_multiplier
		
		# Armazena no GameGlobals para transição de fase
		GameGlobals.current_level_data = level_data
	
	if progress_bar:
		progress_bar.max_value = kills_for_boss
		progress_bar.value = 0
	else:
		push_warning("LevelManager: nó 'UI/BossProgress' não encontrado na cena.")
	
	if boss_label:
		push_warning("LevelManager: nó 'UI/BossLabel' não encontrado na cena.")
	
	if not spawn_area:
		push_warning("LevelManager: nó 'Area2D' não encontrado na cena.")
	if not spawn_col:
		push_warning("LevelManager: nó 'Area2D/Spawn - CollisionShape2D' não encontrado na cena.")
	
	_update_stage_label(current_level_number)

	for existing_enemy in get_tree().get_nodes_in_group("enemy"):
		if existing_enemy.has_signal("died"):
			existing_enemy.died.connect(_on_enemy_died)

	if spawn_timer:
		spawn_timer.wait_time = spawn_interval
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
		spawn_timer.start()
	else:
		push_error("LevelManager: nó 'SpawnTimer' não encontrado! Inimigos não vão spawnar.")


func _cache_scene_nodes() -> void:
	spawn_timer = _find_first_node(["SpawnTimer", "LevelManager/SpawnTimer"]) as Timer
	progress_bar = _find_first_node(["UI/BossProgress", "LevelManager/UI/BossProgress"]) as ProgressBar
	boss_label = _find_first_node(["UI/BossLabel", "LevelManager/UI/BossLabel"]) as Label
	stage_label = _find_first_node(["UI/StageLabel", "LevelManager/UI/StageLabel"]) as Label
	spawn_area = _find_first_node(["Area2D", "Spawn Area"]) as Area2D
	spawn_col = _find_first_node([
		"Area2D/Spawn - CollisionShape2D",
		"Area2D/Spawn",
		"Spawn Area/Spawn"
	]) as CollisionShape2D
	hero_spawn_point = _find_first_node(["HeroSpawnPoint", "HeroSpawn"]) as Marker2D


func _find_first_node(paths: Array[String]) -> Node:
	for p in paths:
		var node = get_node_or_null(p)
		if node:
			return node
	return null


func _update_stage_label(level_number: int) -> void:
	if not stage_label:
		return

	var stage_name = level_data.level_name if level_data and not level_data.level_name.is_empty() else get_tree().current_scene.name
	stage_label.text = "%s - Nível %d" % [stage_name, level_number]

func _on_spawn_timer_timeout() -> void:
	if boss_spawned or flag_spawned:
		return
	if enemy_scenes.is_empty():
		return
	if get_tree().get_nodes_in_group("enemy").size() >= max_enemies:
		return

	# Escolhe um inimigo aleatório da lista
	var random_enemy_scene = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy = random_enemy_scene.instantiate()
	
	enemy.global_position = _get_spawn_position()
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	get_tree().current_scene.add_child(enemy)

func _get_spawn_position() -> Vector2:
	var origin := hero.global_position if hero else Vector2.ZERO

	# tenta achar um ponto na área, respeitando distância mínima do herói
	for _i in range(30):
		var p := _random_point_in_spawn_area()
		if p.distance_to(origin) >= min_spawn_distance:
			return p

	# fallback: qualquer ponto da área (mesmo que perto do herói)
	var fallback := _random_point_in_spawn_area()
	if fallback != Vector2.INF:
		return fallback

	# fallback final (caso a área esteja inválida): seu método antigo por raio
	for _i in range(12):
		var offset := Vector2(
			randf_range(-spawn_radius, spawn_radius),
			randf_range(-spawn_radius, spawn_radius)
		)
		if offset.length() >= min_spawn_distance:
			return origin + offset
	return origin + Vector2(spawn_radius, 0)

func _random_point_in_spawn_area() -> Vector2:
	# se não existir colisor/shape, sinaliza inválido
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
		var rad: float = sqrt(randf()) * r # uniforme no disco
		var local: Vector2 = Vector2(cos(ang), sin(ang)) * rad
		return t * local

	# fallback: centro da área (ou Vector2.INF se preferir)
	return spawn_area.global_position

func _on_enemy_died(_enemy: Node, is_boss: bool) -> void:
	if is_boss:
		_on_boss_defeated()
		return

	kill_count += 1
	if progress_bar:
		progress_bar.value = min(kill_count, kills_for_boss)

	if kill_count >= kills_for_boss and not boss_spawned:
		_spawn_boss()

func _on_boss_defeated() -> void:
	if boss_label:
		boss_label.text = "BOSS DERROTADO!"
	await get_tree().create_timer(1.0).timeout
	_spawn_flag()

func _spawn_flag() -> void:
	if not flag_scene or not hero:
		_show_upgrade_screen()
		return
	
	flag_spawned = true
	
	# Encontra uma posição aleatória longe do herói
	var flag_position = _get_flag_spawn_position()
	
	var flag = flag_scene.instantiate()
	flag.global_position = flag_position
	if flag.has_signal("flag_touched"):
		flag.flag_touched.connect(_on_flag_touched)
	get_tree().current_scene.call_deferred("add_child", flag)

func _get_flag_spawn_position() -> Vector2:
	if not hero:
		return Vector2.ZERO
	
	# Tenta spawnar longe do herói (mínimo 200 pixels)
	const MIN_DISTANCE = 200.0
	const MAX_DISTANCE = 400.0
	
	for _i in range(20):
		var angle = randf() * TAU
		var distance = randf_range(MIN_DISTANCE, MAX_DISTANCE)
		var offset = Vector2(cos(angle), sin(angle)) * distance
		var pos = hero.global_position + offset
		
		# Verifica se está dentro da área de spawn
		if _is_position_in_spawn_area(pos):
			return pos
	
	# Fallback: apenas longe do herói
	var fallback_angle = randf() * TAU
	return hero.global_position + Vector2(cos(fallback_angle), sin(fallback_angle)) * MIN_DISTANCE

func _is_position_in_spawn_area(pos: Vector2) -> bool:
	if not spawn_col or not spawn_col.shape:
		return true
	
	var shape = spawn_col.shape
	var local_pos = spawn_col.global_transform.affine_inverse() * pos
	
	if shape is RectangleShape2D:
		var rect = shape as RectangleShape2D
		var half_size = rect.size * 0.5
		return abs(local_pos.x) <= half_size.x and abs(local_pos.y) <= half_size.y
	elif shape is CircleShape2D:
		var circle = shape as CircleShape2D
		return local_pos.length() <= circle.radius
	
	return true

func _on_flag_touched() -> void:
	flag_spawned = false
	_show_upgrade_screen()

func _show_upgrade_screen() -> void:
	if not upgrade_screen_scene:
		print("Upgrade screen scene não configurada!")
		_go_to_next_level()
		return
	
	# Instancia a tela de upgrade se ainda não existe
	if not upgrade_screen:
		upgrade_screen = upgrade_screen_scene.instantiate()
		add_child(upgrade_screen)
		upgrade_screen.upgrade_selected.connect(_on_upgrade_selected)
	
	# Pausa o jogo
	get_tree().paused = true
	
	# Mostra a tela de upgrade
	if upgrade_screen.has_method("show_upgrades"):
		upgrade_screen.show_upgrades(hero)

func _on_upgrade_selected() -> void:
	# Despausa o jogo
	get_tree().paused = false
	
	# Aguarda um pouco e vai para a próxima fase
	await get_tree().create_timer(0.5).timeout
	_go_to_next_level()

func _go_to_next_level() -> void:
	# Pega a próxima fase
	var next_level_scene = GameGlobals.get_next_level(level_data)
	
	if next_level_scene:
		get_tree().change_scene_to_packed(next_level_scene)
	else:
		print("Nenhuma próxima fase disponível, reiniciando...")
		get_tree().reload_current_scene()

func _spawn_boss() -> void:
	boss_spawned = true
	if boss_label:
		boss_label.visible = true
	if enemy_scenes.is_empty():
		return

	# Escolhe um inimigo aleatório para ser o boss
	var random_enemy_scene = enemy_scenes[randi() % enemy_scenes.size()]
	var boss = random_enemy_scene.instantiate()
	
	boss.global_position = _get_spawn_position()

	if "is_boss" in boss:
		boss.is_boss = true
	if "health" in boss:
		boss.health = int(boss.health * boss_health_multiplier)
	if "damage" in boss:
		boss.damage = int(boss.damage * boss_damage_multiplier)
	if "speed" in boss:
		boss.speed = boss.speed * boss_speed_multiplier

	boss.scale = Vector2(1.4, 1.4)

	if boss.has_signal("died"):
		boss.died.connect(_on_enemy_died)

	get_tree().current_scene.call_deferred("add_child", boss)
	spawn_timer.stop()

func _spawn_hero() -> void:
	# Se o hero_scene não foi configurado, tenta carregar o padrão
	if not hero_scene:
		hero_scene = load("res://characters/hero.tscn")
	
	if not hero_scene:
		push_warning("Hero scene não configurada!")
		return
	
	hero = hero_scene.instantiate()
	
	# Define a posição inicial
	if hero_spawn_point:
		hero.global_position = hero_spawn_point.global_position
	else:
		# Posição padrão no centro da área de spawn
		if spawn_area:
			hero.global_position = spawn_area.global_position
		else:
			hero.global_position = Vector2.ZERO
	
	get_tree().current_scene.add_child(hero)
