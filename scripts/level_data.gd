# ==============================================================================
# LEVEL_DATA.GD - Resource de Configuração de Fase
# ==============================================================================
# Esta classe define um Resource que armazena todas as configurações de uma fase
# ARQUITETURA:
# - Este é um Resource customizado (não um Node)
# - Resources são assets salvos como arquivos .tres no Godot
# - Podem ser reutilizados e editados no Inspector
# - LevelManager carrega um LevelData para configurar a fase
#
# USO:
# 1. Criar novo LevelData resource no FileSystem (New Resource → LevelData)
# 2. Configurar propriedades no Inspector (inimigos, spawn, boss, etc)
# 3. Salvar como .tres (ex: beach_data.tres, forest_data.tres)
# 4. Referenciar no LevelManager da cena da fase (@export var level_data)
#
# EXEMPLOS DE ARQUIVOS:
# - res://resources/levels/beach_data.tres
# - res://resources/levels/forest_data.tres
# ==============================================================================

extends Resource
class_name LevelData

# =========================
# INFORMAÇÕES BÁSICAS
# =========================
# Nome da fase exibido na UI (ex: "Praia", "Floresta")
@export var level_name: String = "Level"

# Array de PackedScenes de próximas fases possíveis
# Se vazio, GameGlobals.get_next_level() usa seleção aleatória
# Se preenchido, próxima fase será escolhida aleatoriamente deste array
# EXEMPLO: [forest.tscn, beach.tscn] → 50% chance de cada
@export var next_levels: Array[PackedScene] = []

# =========================
# CONFIGURAÇÕES DE SPAWN
# =========================
# Array de PackedScenes de inimigos que podem spawnar nesta fase
# Cada spawn seleciona aleatoriamente um inimigo deste array
# EXEMPLO: [goblin.tscn, cow.tscn] → 50% chance de cada
@export var enemy_scenes: Array[PackedScene] = []

# Intervalo em segundos entre cada spawn de inimigo
# Valores menores = spawns mais frequentes = dificuldade maior
@export var spawn_interval: float = 1.0

# Número máximo de inimigos vivos simultaneamente
# Quando atingido, spawns são pausados até que algum inimigo morra
@export var max_enemies: int = 15

# Número de kills necessários para spawnar o boss
# Após atingir este número, timer de spawn para e boss aparece
@export var kills_for_boss: int = 10

# =========================
# CONFIGURAÇÕES DE SPAWN ESPACIAL
# =========================
# Raio máximo em pixels para tentativas de spawn
# Usado como fallback se spawn_area não tiver shape válido
@export var spawn_radius: float = 260.0

# Distância mínima em pixels entre spawn e herói
# Evita spawns muito próximos que matariam instantaneamente
# Valor recomendado: 140-200 pixels
@export var min_spawn_distance: float = 140.0

# =========================
# CONFIGURAÇÕES DE BOSS
# =========================
# Multiplicador de vida do boss
# boss.health = enemy.health * multiplicador
# EXEMPLO: inimigo com 100 HP, multiplicador 3.0 → boss com 300 HP
@export var boss_health_multiplier: float = 3.0

# Multiplicador de dano do boss
# boss.damage = enemy.damage * multiplicador
# EXEMPLO: inimigo com 10 dano, multiplicador 2.0 → boss com 20 dano
@export var boss_damage_multiplier: float = 2.0

# Multiplicador de velocidade do boss
# boss.speed = enemy.speed * multiplicador
# EXEMPLO: inimigo com 30 speed, multiplicador 1.3 → boss com 39 speed
@export var boss_speed_multiplier: float = 1.3
