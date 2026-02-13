extends Resource
class_name EnemyData

# =========================
# CONFIGURAÇÕES BÁSICAS
# =========================
@export var enemy_name: String = "Enemy"
@export var speed: float = 30.0
@export var health: int = 100
@export var damage: int = 10

# =========================
# CONFIGURAÇÕES DE COMBATE
# =========================
@export var shoot_range: float = 100.0
@export var shoot_cooldown: float = 1.5
@export var stop_distance: float = 50.0

# =========================
# CONFIGURAÇÕES DE DROP
# =========================
@export var drop_chance: float = 0.3  # 30% de chance de dropar
@export var health_drop_chance: float = 0.5  # 50% de ser health pickup

# =========================
# CONFIGURAÇÕES VISUAIS
# =========================
@export var hit_flash_duration: float = 0.1

# =========================
# MULTIPLICADORES DE BOSS
# =========================
@export var boss_health_mult: float = 3.0
@export var boss_damage_mult: float = 2.0
@export var boss_speed_mult: float = 1.3
@export var boss_scale: float = 1.4
