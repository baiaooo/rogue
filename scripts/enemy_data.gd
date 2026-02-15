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
# CONFIGURAÇÕES VISUAIS
# =========================
@export var sprite_texture: Texture2D  # Sprite do inimigo
@export var enemy_size: float = 1.0  # Tamanho do sprite (scale)
@export var hit_flash_duration: float = 0.1

# =========================
# CONFIGURAÇÕES DE COMBATE
# =========================
@export_group("Combat")
@export var projectile_scene: PackedScene  # Projétil usado pelo inimigo
@export var shoot_range: float = 100.0
@export var shoot_cooldown: float = 1.5
@export var stop_distance: float = 50.0

# =========================
# COMPORTAMENTO
# =========================
enum Behavior {
	CHASE_AND_SHOOT,  # Persegue o jogador e atira
	MELEE_ONLY,       # Apenas persegue, não atira
	STATIONARY_SHOOTER  # Fica parado e atira
}
@export var behavior: Behavior = Behavior.CHASE_AND_SHOOT

# =========================
# CONFIGURAÇÕES DE DROP
# =========================
@export_group("Drops")
@export var drop_chance: float = 0.3  # 30% de chance de dropar
@export var health_drop_chance: float = 0.5  # 50% de ser health pickup

# =========================
# MULTIPLICADORES DE BOSS
# =========================
@export_group("Boss Multipliers")
@export var boss_health_mult: float = 3.0
@export var boss_damage_mult: float = 2.0
@export var boss_speed_mult: float = 1.3
@export var boss_scale: float = 1.4
