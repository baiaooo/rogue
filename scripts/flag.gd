# ==============================================================================
# FLAG.GD - Sistema de Bandeira / Objetivo de Fase
# ==============================================================================
# Este script controla a bandeira que aparece após derrotar o boss
# FUNCIONALIDADES:
# - Aparece na posição aleatória longe do herói após boss derrotado
# - Efeito visual de flutuação (bobbing)
# - Auto-coleta ao tocar no herói
# - Emite sinal para LevelManager transicionar para tela de upgrades
#
# FLUXO NA FASE:
# 1. Herói mata inimigos até atingir kills_for_boss
# 2. Boss spawna e é derrotado
# 3. LevelManager spawna a bandeira longe do herói
# 4. Herói se move até a bandeira e coleta
# 5. Sinal flag_touched é emitido
# 6. LevelManager mostra tela de upgrades
# 7. Após upgrade, transição para próxima fase
# ==============================================================================

extends Area2D

# =========================
# SINAIS
# =========================
# Emitido quando o herói toca na bandeira
# LevelManager escuta este sinal para mostrar tela de upgrades
signal flag_touched

# =========================
# REFERÊNCIAS AOS NÓS
# =========================
# Sprite visual da bandeira (usado para efeito de bobbing)
@onready var sprite: Sprite2D = $Sprite2D

# Label com texto "OBJETIVO" ou similar (opcional)
@onready var label: Label = $Label

# =========================
# VARIÁVEIS DE BOBBING
# =========================
# Tempo acumulado para cálculo do movimento de flutuação
var bob_time: float = 0.0

# Velocidade do movimento de bobbing (quanto maior, mais rápido)
const BOB_SPEED: float = 3.0

# Amplitude do movimento vertical em pixels
const BOB_AMOUNT: float = 10.0

# Posição Y inicial do nó (referência para bobbing)
var initial_y: float = 0.0


# ==============================================================================
# INICIALIZAÇÃO
# ==============================================================================
# Chamado quando a bandeira entra na árvore de cenas
# FLUXO:
# 1. Adiciona ao grupo "flag" (para rastreamento)
# 2. Armazena posição Y inicial
# 3. Conecta sinal de colisão
# ==============================================================================
func _ready() -> void:
	# ETAPA 1: Adiciona ao grupo "flag"
	# Permite que LevelManager ou outros sistemas identifiquem esta bandeira
	add_to_group("flag")
	
	# ETAPA 2: Armazena posição Y inicial
	# Usado como referência para o efeito de bobbing
	initial_y = position.y
	
	# ETAPA 3: Conecta sinal de colisão
	body_entered.connect(_on_body_entered)


# ==============================================================================
# LOOP PRINCIPAL
# ==============================================================================
# Chamado a cada frame para aplicar efeito de flutuação
# ==============================================================================
func _process(delta: float) -> void:
	# EFEITO DE FLUTUAÇÃO
	# Incrementa tempo acumulado
	bob_time += delta * BOB_SPEED
	
	# Aplica movimento vertical sinusoidal ao sprite
	if sprite:
		# sin() oscila entre -1 e 1
		# Multiplicado por BOB_AMOUNT define amplitude em pixels
		# Modifica apenas sprite.position.y (relativo ao nó pai)
		# para manter global_position constante
		sprite.position.y = sin(bob_time) * BOB_AMOUNT


# ==============================================================================
# SISTEMA DE COLETA
# ==============================================================================
# Detecta colisão com herói e emite sinal para iniciar transição de fase
# ==============================================================================
func _on_body_entered(body: Node2D) -> void:
	# VALIDAÇÃO: Verifica se colidiu com o herói
	if body.is_in_group("player"):
		# ETAPA 1: Emite sinal para LevelManager
		# LevelManager escuta este sinal e chama _show_upgrade_screen()
		emit_signal("flag_touched")
		
		# ETAPA 2: Remove bandeira da cena
		# queue_free() agenda remoção segura no fim do frame
		queue_free()
