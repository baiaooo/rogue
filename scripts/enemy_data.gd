# ==============================================================================
# ENEMY_DATA.GD - Resource de Configuração de Inimigo
# ==============================================================================
# Esta classe define um Resource que armazena todas as configurações de um tipo de inimigo
# ARQUITETURA:
# - Este é um Resource customizado (não um Node)
# - Resources são assets salvos como arquivos .tres no Godot
# - Permite criar "tipos" de inimigos reutilizáveis (Goblin, Vaca, Zumbi, etc)
# - Enemy.gd carrega um EnemyData para configurar suas propriedades
#
# USO:
# 1. Criar novo EnemyData resource no FileSystem (New Resource → EnemyData)
# 2. Configurar todas as propriedades no Inspector
# 3. Salvar como .tres (ex: goblin_data.tres, cow_data.tres)
# 4. Referenciar no Enemy da cena (@export var enemy_data)
#
# VANTAGEM:
# - Facilita criar variações de inimigos sem duplicar cenas
# - Permite ajustar balance (HP, dano, velocidade) em um lugar central
# - Designers podem criar novos tipos sem tocar em código
# ==============================================================================

extends Resource
class_name EnemyData

# =========================
# CONFIGURAÇÕES BÁSICAS
# =========================
# Nome descritivo do tipo de inimigo (ex: "Goblin", "Vaca", "Zumbi")
# Usado apenas para identificação, não é exibido no jogo
@export var enemy_name: String = "Enemy"

# Velocidade de movimento em pixels por segundo
@export var speed: float = 30.0

# Pontos de vida do inimigo (antes de multiplicadores de boss)
@export var health: int = 100

# Dano causado ao colidir com o herói
# Nota: Dano de projéteis é configurado separadamente em enemy.gd._shoot_at_player()
@export var damage: int = 10

# =========================
# CONFIGURAÇÕES VISUAIS
# =========================
# Textura do sprite do inimigo
# Se configurado, substitui a textura padrão do sprite na cena
@export var sprite_texture: Texture2D

# Escala do sprite (1.0 = tamanho original)
# Usado para ajustar tamanho visual sem modificar colisões
# EXEMPLO: 0.5 = metade do tamanho, 2.0 = dobro do tamanho
@export var enemy_size: float = 1.0

# Duração em segundos do flash vermelho ao tomar dano
@export var hit_flash_duration: float = 0.1

# =========================
# CONFIGURAÇÕES DE COMBATE
# =========================
@export_group("Combat")

# Cena do projétil disparado por este inimigo
# Se null, inimigo não pode atirar (apenas corpo a corpo)
@export var projectile_scene: PackedScene

# Distância máxima em pixels dentro da qual o inimigo pode atirar
# Só é relevante para comportamentos que atiram
@export var shoot_range: float = 100.0

# Tempo em segundos entre cada disparo (cooldown)
@export var shoot_cooldown: float = 1.5

# Distância em pixels onde inimigo para de se aproximar
# Usado apenas no comportamento CHASE_AND_SHOOT
# EXEMPLO: 50.0 = para a 50 pixels do herói e começa a atirar
@export var stop_distance: float = 50.0

# =========================
# COMPORTAMENTO
# =========================
# Enum definindo os tipos de comportamento disponíveis
enum Behavior {
	CHASE_AND_SHOOT,       # Persegue até stop_distance, depois para e atira
	MELEE_ONLY,            # Persegue constantemente, nunca atira (corpo a corpo)
	STATIONARY_SHOOTER     # Fica parado, apenas atira quando herói entra no alcance
}

# Comportamento deste tipo de inimigo
# Define padrão de movimento e combate
@export var behavior: Behavior = Behavior.CHASE_AND_SHOOT

# =========================
# CONFIGURAÇÕES DE DROP
# =========================
@export_group("Drops")

# Probabilidade de dropar pickup ao morrer (0.0 a 1.0)
# EXEMPLO: 0.3 = 30% de chance de dropar algo
@export var drop_chance: float = 0.3

# Probabilidade de ser health pickup quando dropar (0.0 a 1.0)
# EXEMPLO: 0.5 = 50% health, 50% reroll
# EXEMPLO: 0.8 = 80% health, 20% reroll
@export var health_drop_chance: float = 0.5

# =========================
# MULTIPLICADORES DE BOSS
# =========================
# Estes valores são usados se este inimigo for transformado em boss
# LevelManager aplica estes multiplicadores quando spawna o boss

@export_group("Boss Multipliers")

# Multiplicador de vida quando é boss
# EXEMPLO: health = 100, boss_health_mult = 3.0 → boss com 300 HP
@export var boss_health_mult: float = 3.0

# Multiplicador de dano quando é boss
# EXEMPLO: damage = 10, boss_damage_mult = 2.0 → boss com 20 dano
@export var boss_damage_mult: float = 2.0

# Multiplicador de velocidade quando é boss
# EXEMPLO: speed = 30, boss_speed_mult = 1.3 → boss com 39 speed
@export var boss_speed_mult: float = 1.3

# Escala visual quando é boss (tamanho maior que inimigos normais)
# LevelManager aplica boss.scale = Vector2(boss_scale, boss_scale)
@export var boss_scale: float = 1.4
