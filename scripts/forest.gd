extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 4.0
@export var max_enemies: int = 6
@export var kills_for_boss: int = 10
@export var spawn_radius: float = 260.0 # fallback (se não tiver spawn_area)
@export var min_spawn_distance: float = 140.0
@export var boss_health_multiplier: float = 3.0
@export var boss_damage_multiplier: float = 2.0
@export var boss_speed_multiplier: float = 1.3
@export var upgrade_screen_scene: PackedScene  # Arraste a cena de upgrade aqui

var kill_count: int = 0
var boss_spawned: bool = false
var upgrade_screen: Control = null

@onready var hero: Node2D = $hero
@onready var spawn_timer: Timer = $SpawnTimer
@onready var progress_bar: ProgressBar = $UI/BossProgress
@onready var boss_label: Label = $UI/BossLabel

@onready var spawn_area: Area2D = $Area2D
@onready var spawn_col: CollisionShape2D = $Area2D/"Spawn - CollisionShape2D"

func _ready() -> void:
	randomize()

	progress_bar.max_value = kills_for_boss
	progress_bar.value = 0
	boss_label.visible = false

	for existing_enemy in get_tree().get_nodes_in_group("enemy"):
		if existing_enemy.has_signal("died"):
			existing_enemy.died.connect(_on_enemy_died)

	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if boss_spawned:
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
func _on_enemy_died(enemy: Node, is_boss: bool) -> void:
	if is_boss:
		_on_boss_defeated()
		return

	kill_count += 1
	progress_bar.value = min(kill_count, kills_for_boss)

	if kill_count >= kills_for_boss and not boss_spawned:
		_spawn_boss()

func _on_boss_defeated() -> void:
	boss_label.text = "BOSS DERROTADO!"
	await get_tree().create_timer(1.0).timeout
	_show_upgrade_screen()

func _show_upgrade_screen() -> void:
	if not upgrade_screen_scene:
		print("Upgrade screen scene não configurada!")
		_restart_level()
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
	
	# Aguarda um pouco e reinicia o level
	await get_tree().create_timer(0.5).timeout
	_restart_level()

func _restart_level() -> void:
	# Reseta variáveis
	kill_count = 0
	boss_spawned = false
	progress_bar.value = 0
	boss_label.visible = false
	
	# Remove todos os inimigos
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.queue_free()
	
	# Reinicia o spawn timer
	spawn_timer.start()
	
	# Opcional: curar o herói um pouco
	if hero and hero.has_method("heal"):
		var heal_amount = int(hero.max_health * 0.5) if "max_health" in hero else 50
		hero.heal(heal_amount)

func _spawn_boss() -> void:
	boss_spawned = true
	boss_label.visible = true
	if not enemy_scene:
		return

	var boss = enemy_scene.instantiate()
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
