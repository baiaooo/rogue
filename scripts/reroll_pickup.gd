# ==============================================================================
# REROLL_PICKUP.GD - Sistema de Pickup de Reroll
# ==============================================================================
# Este script controla pickups que concedem rerolls ao herói quando coletados
# FUNCIONALIDADES:
# - Adiciona 1 reroll ao contador do herói
# - Efeito visual de pulsação de cor (amarelo/laranja)
# - Efeito de "bobbing" (flutuar para cima e baixo)
# - Efeito de rotação contínua
# - Auto-coleta ao tocar no herói
# - Label visual com nome do pickup
#
# REROLLS:
# Rerolls permitem ao jogador "recarregar" opções de upgrade na tela de upgrades
# Cada reroll consome 1 do contador e gera 3 novas opções aleatórias
#
# SPAWN:
# Dropado por inimigos ao morrer (chance definida em enemy.gd)
# Probabilidade de ser reroll vs health definida por health_drop_chance
# ==============================================================================

extends Area2D

# =========================
# CONFIGURAÇÕES DO PICKUP
# =========================
# Cores do efeito de pulsação (amarelo/laranja para tema de reroll)
@export var color_1: Color = Color(1.0, 0.8, 0.0)  # Amarelo brilhante
@export var color_2: Color = Color(1.0, 0.4, 0.0)  # Laranja

# Velocidade da transição entre cores (quanto maior, mais rápido)
@export var color_change_speed: float = 3.0

# Velocidade do movimento de "bobbing" (flutuar)
@export var bob_speed: float = 2.0

# Amplitude do movimento vertical em pixels
@export var bob_amount: float = 5.0

# Velocidade de rotação em radianos por segundo
@export var rotation_speed: float = 2.0

# =========================
# VARIÁVEIS INTERNAS
# =========================
# Tempo acumulado para cálculo da interpolação de cor
var color_time: float = 0.0

# Tempo acumulado para cálculo do movimento de bobbing
var bob_time: float = 0.0

# Posição Y inicial do pickup (referência para bobbing)
var initial_y: float = 0.0

# =========================
# REFERÊNCIAS AOS NÓS
# =========================
# Sprite visual do pickup (usado para efeitos de cor e rotação)
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

# Label com nome do pickup (exibido acima do sprite)
@onready var pickup_name_label: Label = $PickupName if has_node("PickupName") else null


# ==============================================================================
# INICIALIZAÇÃO
# ==============================================================================
# Chamado quando o pickup entra na árvore de cenas
# FLUXO:
# 1. Armazena posição Y inicial (referência para bobbing)
# 2. Define texto do label
# 3. Conecta sinal de colisão
# ==============================================================================
func _ready() -> void:
	# ETAPA 1: Armazena posição Y inicial
	# Necessário porque o bobbing modifica position.y continuamente
	initial_y = position.y
	
	# ETAPA 2: Configura label com nome
	if pickup_name_label:
		pickup_name_label.text = "Reroll"
	
	# ETAPA 3: Conecta sinal de colisão com herói
	body_entered.connect(_on_body_entered)


# ==============================================================================
# LOOP DE FÍSICA
# ==============================================================================
# Chamado a cada frame de física (60 FPS)
# Aplica efeitos visuais de cor, movimento e rotação
# ==============================================================================
func _physics_process(delta: float) -> void:
	# Efeito de pulsação de cor amarelo/laranja
	_apply_color_change(delta)
	
	# Efeito de flutuar para cima e para baixo
	_apply_bobbing(delta)
	
	# Efeito de rotação contínua
	_apply_rotation(delta)


# ==============================================================================
# EFEITOS VISUAIS
# ==============================================================================
# Efeitos de feedback visual para indicar que é coletável
# Reroll tem efeito adicional de rotação comparado ao health pickup
# ==============================================================================

# Efeito de pulsação de cor - interpola entre amarelo e laranja
# Usa função seno para transição suave e cíclica
func _apply_color_change(delta: float) -> void:
	# VALIDAÇÃO: Sprite existe
	if not sprite:
		return
	
	# ETAPA 1: Incrementa tempo acumulado
	color_time += delta * color_change_speed
	
	# ETAPA 2: Calcula fator de interpolação (0.0 a 1.0)
	# sin() varia entre -1 e 1
	# (sin() + 1) / 2 normaliza para 0.0 a 1.0
	var blend_factor = (sin(color_time) + 1.0) / 2.0
	
	# ETAPA 3: Interpola entre as duas cores
	var current_color = color_1.lerp(color_2, blend_factor)
	
	# ETAPA 4: Aplica cor ao sprite
	sprite.modulate = current_color

# Efeito de bobbing - movimento vertical suave para cima e para baixo
# Cria ilusão de que o pickup está "flutuando"
func _apply_bobbing(delta: float) -> void:
	# ETAPA 1: Incrementa tempo de bobbing
	bob_time += delta * bob_speed
	
	# ETAPA 2: Calcula offset vertical usando seno
	# sin() oscila entre -1 e 1
	# Multiplicado por bob_amount define amplitude em pixels
	var offset = sin(bob_time) * bob_amount
	
	# ETAPA 3: Aplica offset à posição Y
	# Usa initial_y como referência para manter posição base
	position.y = initial_y + offset

# Efeito de rotação contínua - diferencial do reroll pickup
# Sprite gira continuamente no próprio eixo
func _apply_rotation(delta: float) -> void:
	if sprite:
		# Adiciona rotação incremental a cada frame
		# rotation_speed em radianos por segundo
		sprite.rotation += delta * rotation_speed


# ==============================================================================
# SISTEMA DE COLETA
# ==============================================================================
# Detecta colisão com herói e adiciona 1 reroll ao contador
# Rerolls são usados na tela de upgrades para gerar novas opções
# ==============================================================================
func _on_body_entered(body: Node2D) -> void:
	# VALIDAÇÃO 1: Verifica se colidiu com o herói
	if not body.is_in_group("player"):
		return
	
	# ETAPA 1: Adiciona reroll ao herói
	# Tenta usar método add_reroll() primeiro (preferível)
	if body.has_method("add_reroll"):
		body.add_reroll()
	# Senão, incrementa propriedade reroll_count diretamente
	elif "reroll_count" in body:
		body.reroll_count += 1
	
	# ETAPA 2: Remove o pickup da cena após coleta
	queue_free()
