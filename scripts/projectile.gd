# ==============================================================================
# PROJECTILE.GD - Sistema de Projéteis
# ==============================================================================
# Este script controla os projéteis disparados pelo herói e inimigos
# FUNCIONALIDADES:
# - Movimento em linha reta na direção definida
# - Auto-destruição após tempo de vida (lifetime)
# - Sistema de times (player/enemy) para evitar friendly fire
# - Efeito visual de pulsação de cor
# - Detecção de colisão e aplicação de dano
# - Rotação automática baseada na direção
#
# USO:
# 1. Herói/Inimigo instancia a cena do projétil
# 2. Define posição inicial (global_position)
# 3. Chama set_direction(vetor) para definir direção
# 4. Chama set_team("player" ou "enemy")
# 5. Opcional: Ajusta speed, damage, lifetime, cores
# 6. Adiciona à cena (add_child)
# ==============================================================================

extends Area2D

# =========================
# CONFIGURAÇÕES DO PROJÉTIL
# =========================
# Velocidade de movimento em pixels por segundo
@export var speed: float = 400.0

# Tempo de vida em segundos (auto-destruição)
# 0 = não se auto-destrói (não recomendado - pode vazar memória)
@export var lifetime: float = 3.0

# Dano causado ao atingir alvo
@export var damage: int = 20

# Time do projétil: "player" (disparado pelo herói) ou "enemy" (disparado por inimigo)
# Usado para evitar friendly fire (projéteis não atingem membros do mesmo time)
@export var team: String = "player"

# =========================
# CONFIGURAÇÕES DE COR
# =========================
# Primeira cor do efeito de pulsação
@export var color_1: Color = Color.RED

# Segunda cor do efeito de pulsação
@export var color_2: Color = Color.YELLOW

# Velocidade da transição entre cores (quanto maior, mais rápido)
@export var color_change_speed: float = 5.0

# =========================
# VARIÁVEIS INTERNAS
# =========================
# Direção normalizada do movimento (vetor unitário)
var direction: Vector2 = Vector2.RIGHT

# Tempo acumulado para cálculo da interpolação de cor
var color_time: float = 0.0

# =========================
# REFERÊNCIAS AOS NÓS
# =========================
# Sprite visual do projétil (usado para efeito de cor)
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null


# ==============================================================================
# INICIALIZAÇÃO
# ==============================================================================
# Chamado quando o projétil entra na árvore de cenas
# FLUXO:
# 1. Conecta sinais de colisão
# 2. Inicia timer de auto-destruição
# ==============================================================================
func _ready() -> void:
	# ETAPA 1: Conecta sinais de colisão
	# body_entered: Detecta colisão com CharacterBody2D (herói, inimigos)
	body_entered.connect(_on_body_entered)
	
	# area_entered: Detecta colisão com outros Area2D (outros projéteis, paredes)
	area_entered.connect(_on_area_entered)

	# ETAPA 2: Sistema de auto-destruição
	if lifetime > 0:
		# Aguarda lifetime segundos e depois destrói o projétil
		await get_tree().create_timer(lifetime).timeout
		queue_free()


# ==============================================================================
# LOOP DE FÍSICA
# ==============================================================================
# Chamado a cada frame de física (60 FPS)
# FLUXO:
# 1. Move o projétil na direção definida
# 2. Aplica efeito de mudança de cor
# ==============================================================================
func _physics_process(delta: float) -> void:
	# ETAPA 1: Movimento
	# position += velocity * deltaTime (fórmula básica de movimento)
	position += direction * speed * delta
	
	# ETAPA 2: Efeito visual de cor pulsante
	_apply_color_change(delta)


# ==============================================================================
# SISTEMA DE MUDANÇA DE COR
# ==============================================================================
# Cria efeito de pulsação interpolando entre color_1 e color_2
# Usa função seno para transição suave e cíclica
# ==============================================================================
func _apply_color_change(delta: float) -> void:
	# VALIDAÇÃO: Sprite existe
	if not sprite:
		return

	# ETAPA 1: Incrementa tempo acumulado
	color_time += delta * color_change_speed
	
	# ETAPA 2: Calcula fator de interpolação usando seno
	# sin() varia entre -1 e 1
	# (sin() + 1) / 2 normaliza para variar entre 0 e 1
	var blend_factor = (sin(color_time) + 1.0) / 2.0
	
	# ETAPA 3: Interpola entre as duas cores
	# lerp = Linear intERPolation
	# blend_factor 0.0 = 100% color_1
	# blend_factor 1.0 = 100% color_2
	# blend_factor 0.5 = 50% de cada
	var current_color = color_1.lerp(color_2, blend_factor)
	
	# ETAPA 4: Aplica cor ao sprite
	sprite.modulate = current_color


# ==============================================================================
# CONFIGURAÇÃO DE DIREÇÃO E TIME
# ==============================================================================
# Funções auxiliares para configurar o projétil após instanciação
# ==============================================================================

# Define a direção de movimento do projétil
# @param dir: Vetor direção (será normalizado automaticamente)
# EFEITO COLATERAL: Também rotaciona o projétil para apontar na direção
func set_direction(dir: Vector2) -> void:
	# Normaliza para garantir magnitude 1.0 (velocidade consistente)
	direction = dir.normalized()
	
	# Rotaciona o projétil para apontar na direção de movimento
	# angle() retorna o ângulo do vetor em radianos
	rotation = direction.angle()

# Define o time do projétil
# @param team_name: "player" ou "enemy"
func set_team(team_name: String) -> void:
	team = team_name


# ==============================================================================
# SISTEMA DE COLISÃO
# ==============================================================================
# Detecta colisões e aplica dano aos alvos válidos
# REGRA: Projéteis não atingem membros do próprio time
# ==============================================================================

# Chamado quando o projétil colide com um CharacterBody2D
# @param body: Nó que colidiu (herói ou inimigo)
func _on_body_entered(body: Node2D) -> void:
	# VALIDAÇÃO 1: Ignora colisões com próprio time (friendly fire)
	# Ex: Projétil "player" não atinge nós no grupo "player"
	if body.is_in_group(team):
		return

	# ETAPA 1: Determina o grupo alvo baseado no time
	# Se time = "enemy", alvo = "player"
	# Se time = "player", alvo = "enemy"
	var target_group := "player" if team == "enemy" else "enemy"
	
	# ETAPA 2: Verifica se colidiu com alvo válido
	if body.is_in_group(target_group):
		# ETAPA 3: Aplica dano se o alvo tem método take_damage
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		# ETAPA 4: Destrói o projétil após acertar
		queue_free()
		return
	
	# FALLBACK: Destrói projétil ao colidir com qualquer outro corpo
	# (paredes, obstáculos, etc)
	queue_free()

# Chamado quando o projétil colide com outro Area2D
# @param area: Area2D que colidiu (outro projétil, pickup, etc)
# COMPORTAMENTO: Simplesmente destrói o projétil
func _on_area_entered(area: Area2D) -> void:
	queue_free()
