extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 4.0
@export var max_enemies: int = 6
@export var kills_for_boss: int = 10
@export var spawn_radius: float = 260.0
@export var min_spawn_distance: float = 140.0
@export var boss_health_multiplier: float = 3.0
@export var boss_damage_multiplier: float = 2.0
@export var boss_speed_multiplier: float = 1.3

var kill_count: int = 0
var boss_spawned: bool = false

@onready var hero: Node2D = $hero
@onready var spawn_timer: Timer = $SpawnTimer
@onready var progress_bar: ProgressBar = $UI/BossProgress
@onready var boss_label: Label = $UI/BossLabel

func _ready() -> void:
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
	var origin = hero.global_position if hero else Vector2.ZERO
	for _i in range(12):
		var offset = Vector2(
			randf_range(-spawn_radius, spawn_radius),
			randf_range(-spawn_radius, spawn_radius)
		)
		if offset.length() >= min_spawn_distance:
			return origin + offset
	return origin + Vector2(spawn_radius, 0)

func _on_enemy_died(enemy: Node, is_boss: bool) -> void:
	if is_boss:
		return
	kill_count += 1
	progress_bar.value = min(kill_count, kills_for_boss)
	if kill_count >= kills_for_boss and not boss_spawned:
		_spawn_boss()

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
	get_tree().current_scene.add_child(boss)
	spawn_timer.stop()
