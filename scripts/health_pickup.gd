# ==============================================================================
# HEALTH_PICKUP.GD - Sistema de Pickup de Cura
# ==============================================================================
# Este script controla pickups que curam o herói quando coletados
# FUNCIONALIDADES:
# - Cura baseada em porcentagem da vida máxima (não valor fixo)
# - Efeito visual de pulsação de cor (verde claro/escuro)
# - Efeito de "bobbing" (flutuar para cima e baixo)
# - Auto-coleta ao tocar no herói
# - Label visual com nome do pickup
#
# SPAWN:
# Dropado por inimigos ao morrer (chance definida em enemy.gd)
# Probabilidade de ser health vs reroll definida por health_drop_chance
#
# CÁLCULO DE CURA:
# heal_amount = max_health * heal_percent
# Exemplo: max_health=100, heal_percent=0.3 → cura 30 pontos
# ==============================================================================

extends Area2D

# =========================
# CONFIGURAÇÕES DO PICKUP
# =========================
# Porcentagem da vida máxima do herói que será curada
# 0.3 = 30% da vida máxima
# Exemplo: Se herói tem 100 de max_health, cura 30
@export var heal_percent: float = 0.3

# Cores do efeito de pulsação (verde claro/escuro para tema de cura)
@export var color_1: Color = Color(0.0, 1.0, 0.3)  # Verde claro brilhante
@export var color_2: Color = Color(0.0, 0.6, 0.2)  # Verde escuro

# Velocidade da transição entre cores (quanto maior, mais rápido)
@export var color_change_speed: float = 3.0

# Velocidade do movimento de "bobbing" (flutuar)
@export var bob_speed: float = 2.0

# Amplitude do movimento vertical em pixels
@export var bob_amount: float = 5.0

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
# Sprite visual do pickup (usado para efeito de cor)
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
		pickup_name_label.text = "Cura"
	
	# ETAPA 3: Conecta sinal de colisão com herói
	body_entered.connect(_on_body_entered)


# ==============================================================================
# LOOP DE FÍSICA
# ==============================================================================
# Chamado a cada frame de física (60 FPS)
# Aplica efeitos visuais de cor e movimento
# ==============================================================================
func _physics_process(delta: float) -> void:
	# Efeito de pulsação de cor verde
	_apply_color_change(delta)
	
	# Efeito de flutuar para cima e para baixo
	_apply_bobbing(delta)


# ==============================================================================
# EFEITOS VISUAIS
# ==============================================================================
# Efeitos de feedback visual para indicar que é coletável
# ==============================================================================

# Efeito de pulsação de cor - interpola entre verde claro e escuro
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


# ==============================================================================
# SISTEMA DE COLETA
# ==============================================================================
# Detecta colisão com herói e aplica cura
# CÁLCULO: Cura = max_health do herói * heal_percent
# ==============================================================================
func _on_body_entered(body: Node2D) -> void:
	# VALIDAÇÃO 1: Verifica se colidiu com o herói
	if not body.is_in_group("player"):
		return
	
	# VALIDAÇÃO 2: Verifica se herói tem método heal()
	if body.has_method("heal"):
		# ETAPA 1: Calcula quantidade de cura
		var heal_amount = 0
		
		# Tenta usar porcentagem da vida máxima do herói
		if "max_health" in body:
			heal_amount = int(body.max_health * heal_percent)
		else:
			# Fallback: valor fixo se max_health não existir
			heal_amount = 30
		
		# ETAPA 2: Aplica cura ao herói
		body.heal(heal_amount)
	
	# ETAPA 3: Remove o pickup da cena após coleta
	queue_free()
