extends Resource
class_name LevelData

# =========================
# INFORMAÇÕES BÁSICAS
# =========================
@export var level_name: String = "Level"
@export var next_levels: Array[PackedScene] = []  # Próximas fases possíveis

# =========================
# CONFIGURAÇÕES DE SPAWN
# =========================
@export var enemy_scenes: Array[PackedScene] = []  # Inimigos que podem aparecer
@export var spawn_interval: float = 4.0
@export var max_enemies: int = 6
@export var kills_for_boss: int = 10

# =========================
# CONFIGURAÇÕES DE SPAWN ESPACIAL
# =========================
@export var spawn_radius: float = 260.0
@export var min_spawn_distance: float = 140.0

# =========================
# CONFIGURAÇÕES DE BOSS
# =========================
@export var boss_health_multiplier: float = 3.0
@export var boss_damage_multiplier: float = 2.0
@export var boss_speed_multiplier: float = 1.3
