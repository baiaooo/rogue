# ==============================================================================
# HERO.GD - Sistema de Controle do Herói
# ==============================================================================
# Este script controla o personagem jogável (herói), incluindo:
# - Movimento em 8 direções (WASD/Setas)
# - Sistema de dash (espaço) com velocidade e duração configuráveis
# - Disparo de projéteis direcionado pelo mouse (botão esquerdo)
# - Sistema de saúde com feedback visual (flash vermelho ao tomar dano)
# - Sistema de upgrades (multiplicadores de dano, velocidade, cadência de tiro)
# - Efeito visual wobble (rotação) durante movimento
# - Sistema de rerolls (recargas de upgrades)
#
# CONTROLES PADRÃO:
# - WASD/Setas: Movimento
# - Espaço: Dash
# - Mouse Esquerdo (segurar): Atirar na direção do cursor
# ==============================================================================

extends CharacterBody2D

# =========================
# VARIÁVEIS DE JOGADOR
# =========================
# ID do controlador (suporte para multiplayer futuro)
# Apenas controller_id == 1 processa inputs atualmente
@export var controller_id: int = 1

# =========================
# STATS DE VIDA
# =========================
# Vida máxima do herói (usada para calcular cura e barra de vida)
@export var max_health: int = 100

# Vida atual (quando chega a 0, game over)
@export var current_health: int = 100

# Duração em segundos do flash vermelho ao tomar dano
@export var hit_flash_duration: float = 0.1

# =========================
# STATS DE REROLL
# =========================
# Quantidade de rerolls acumulados (permite recarregar opções de upgrade)
var reroll_count: int = 0

# =========================
# MULTIPLICADORES DE UPGRADE
# =========================
# Multiplicador de dano dos projéteis (1.0 = dano base, 2.0 = dano dobrado)
var damage_multiplier: float = 1.0

# Multiplicador de velocidade de movimento (1.0 = velocidade base, 1.5 = 50% mais rápido)
var speed_multiplier: float = 1.0

# Multiplicador de cadência de tiro (valores menores = mais rápido, 0.5 = atira 2x mais rápido)
var fire_rate_multiplier: float = 1.0

# Bônus de velocidade adicional ao dash (somado ao DASH_SPEED)
var dash_speed_bonus: int = 0

# Bônus de duração adicional ao dash em segundos (somado ao DASH_DURATION)
var dash_duration_bonus: float = 0.0

# =========================
# STATS DE MOVIMENTO
# =========================
# Velocidade base de movimento em pixels por segundo
const SPEED: int = 100

# Velocidade durante o dash em pixels por segundo
const DASH_SPEED: int = 300

# Duração do dash em segundos
const DASH_DURATION: float = 0.2

# =========================
# STATS DE DISPARO
# =========================
# Cena do projétil que o herói dispara (configurar no Inspector)
@export var projectile_scene: PackedScene

# Tempo mínimo entre tiros em segundos (cadência base)
const FIRE_RATE: float = 0.15

# =========================
# VARIÁVEIS DE WOBBLE (ROTAÇÃO)
# =========================
# Velocidade da oscilação (quanto maior, mais rápido oscila)
const WOBBLE_SPEED: float = 10.0

# Intensidade da rotação em graus (amplitude da oscilação)
const WOBBLE_AMOUNT: float = 15.0

# =========================
# VARIÁVEIS INTERNAS
# =========================
# Flag indicando se está executando um dash
var is_dashing: bool = false

# Direção do dash atual (vetor normalizado)
var dash_direction: Vector2 = Vector2.ZERO

# Timer decrescente que controla duração do dash
var dash_timer: float = 0.0

# Flag indicando se pode atirar (false durante cooldown)
var can_shoot: bool = true

# Timer decrescente para controlar cooldown entre tiros
var shoot_timer: float = 0.0

# Tempo acumulado para cálculo da oscilação wobble
var wobble_time: float = 0.0

# Rotação original do sprite (antes do wobble)
var original_rotation: float = 0.0

# Flag indicando se está no meio do efeito visual de hit
var is_hit: bool = false

# =========================
# REFERÊNCIAS AOS NÓS FILHOS
# =========================
# Sprite visual do herói (usado para wobble e flash de hit)
@onready var sprite: Node2D = $Sprite2D if has_node("Sprite2D") else null

# Barra de vida visual acima do herói
@onready var health_bar: ProgressBar = $HealthBar if has_node("HealthBar") else null


# ==============================================================================
# INICIALIZAÇÃO
# ==============================================================================
# Chamado quando o nó entra na árvore de cenas
# FLUXO:
# 1. Adiciona ao grupo "player" (para que inimigos possam encontrá-lo)
# 2. Inicializa saúde no valor máximo
# 3. Atualiza barra de vida
# 4. Salva rotação original do sprite (para efeito wobble)
# ==============================================================================
func _ready() -> void:
	# ETAPA 1: Registro no grupo "player"
	# Inimigos usam get_tree().get_nodes_in_group("player") para encontrar o herói
	add_to_group("player")
	
	# ETAPA 2: Inicializa saúde no máximo
	current_health = max_health
	
	# ETAPA 3: Sincroniza barra de vida com saúde inicial
	_update_health_bar()
	
	# ETAPA 4: Salva rotação original para referência do wobble
	if sprite:
		original_rotation = sprite.rotation


# ==============================================================================
# LOOP PRINCIPAL DE FÍSICA
# ==============================================================================
# Chamado a cada frame de física (60 FPS)
# FLUXO:
# 1. Verifica se é o controlador ativo (suporte multiplayer futuro)
# 2. Processa dash OU movimento normal (mutuamente exclusivos)
# 3. Processa sistema de disparo (independente de movimento/dash)
# 4. Aplica movimento calculado
# ==============================================================================
func _physics_process(delta: float) -> void:
	# VALIDAÇÃO: Apenas o controlador ativo processa inputs
	# Isso permite suporte futuro para multiplayer local
	if controller_id != 1:
		return
	
	# ETAPA 1: Sistema de movimento
	# Dash tem prioridade sobre movimento normal
	if is_dashing:
		_process_dash(delta)
	else:
		_process_movement(delta)
	
	# ETAPA 2: Sistema de disparo (funciona durante dash ou movimento)
	_process_shooting(delta)
	
	# ETAPA 3: Aplica o movimento calculado
	# move_and_slide() usa velocity para mover e gerencia colisões
	move_and_slide()


# ==============================================================================
# MOVIMENTO NORMAL
# ==============================================================================
# Processa input de movimento WASD/Setas e aplica velocidade
# FLUXO:
# 1. Captura direção do input (8 direções possíveis)
# 2. Normaliza para movimento uniforme em diagonais
# 3. Aplica velocidade com multiplicador de upgrade
# 4. Ativa efeito wobble se em movimento
# 5. Detecta input de dash (espaço)
# ==============================================================================
func _process_movement(delta: float) -> void:
	# ETAPA 1: Captura direção do input
	# Calcula vetor direção baseado em teclas pressionadas
	# get_action_strength retorna 0.0 (solto) ou 1.0 (pressionado)
	var dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	
	# ETAPA 2: Normalização da direção
	# Sem normalização: diagonal seria ~1.41x mais rápido (Pitágoras)
	# Com normalização: todas as direções têm mesma velocidade
	if dir != Vector2.ZERO:
		dir = dir.normalized()
	
	# ETAPA 3: Calcula velocidade
	# Multiplica direção por velocidade base e multiplicador de upgrade
	velocity = dir * SPEED * speed_multiplier
	
	# ETAPA 4: Efeito visual wobble
	if velocity.length() > 0:
		# Em movimento: aplica oscilação de rotação
		_apply_wobble(delta)
	else:
		# Parado: reseta rotação para original
		_reset_wobble()
	
	# ETAPA 5: Detecta input de dash
	# ui_accept = Espaço por padrão
	if Input.is_action_just_pressed("ui_accept"):
		# Se não está se movendo, dash para a direita por padrão
		_start_dash(dir if dir != Vector2.ZERO else Vector2.RIGHT)


# ==============================================================================
# SISTEMA DE DASH
# ==============================================================================
# Dash é um movimento rápido e curto em uma direção
# Durante dash, input de movimento é ignorado (movimento travado)
# ==============================================================================

# Inicia um dash na direção especificada
# @param direction: Vetor direção do dash (será normalizado)
func _start_dash(direction: Vector2) -> void:
	is_dashing = true  # Bloqueia movimento normal
	dash_direction = direction.normalized()  # Garante magnitude 1.0
	dash_timer = DASH_DURATION + dash_duration_bonus  # Duração total com bônus de upgrade

# Processa o dash ativo
# FLUXO:
# 1. Decrementa timer
# 2. Se acabou: desativa dash e para movimento
# 3. Se continua: mantém velocidade de dash
func _process_dash(delta: float) -> void:
	# ETAPA 1: Atualiza timer
	dash_timer -= delta
	
	if dash_timer <= 0:
		# ETAPA 2: Dash terminou
		is_dashing = false
		velocity = Vector2.ZERO  # Para movimento brusco
	else:
		# ETAPA 3: Mantém velocidade de dash
		# Soma velocidade base com bônus de upgrade
		velocity = dash_direction * (DASH_SPEED + dash_speed_bonus)


# ==============================================================================
# EFEITO WOBBLE (ROTAÇÃO)
# ==============================================================================
# Cria oscilação visual de rotação durante movimento
# Usa função seno para criar movimento suave e contínuo
# ==============================================================================

# Aplica rotação oscilante ao sprite durante movimento
# @param delta: Delta time para incremento suave
func _apply_wobble(delta: float) -> void:
	if not sprite:
		return
	
	# ETAPA 1: Incrementa tempo acumulado
	# Multiplicado por WOBBLE_SPEED para controlar frequência
	wobble_time += delta * WOBBLE_SPEED
	
	# ETAPA 2: Calcula rotação usando seno
	# sin() oscila entre -1 e 1, criando movimento suave
	# deg_to_rad converte WOBBLE_AMOUNT de graus para radianos
	var wobble_rotation = sin(wobble_time) * deg_to_rad(WOBBLE_AMOUNT)
	
	# ETAPA 3: Aplica rotação relativa à rotação original
	# Isso mantém a orientação base do sprite
	sprite.rotation = original_rotation + wobble_rotation

# Reseta sprite para rotação original (quando parado)
func _reset_wobble() -> void:
	if not sprite:
		return
	
	# Volta à rotação original
	sprite.rotation = original_rotation
	
	# Reseta tempo acumulado para começar do zero no próximo movimento
	wobble_time = 0.0


# ==============================================================================
# SISTEMA DE DISPARO
# ==============================================================================
# Dispara projéteis na direção do cursor do mouse
# Funciona por "segurar" o botão esquerdo do mouse (auto-fogo)
# ==============================================================================

# Processa cooldown de tiro e detecta input de disparo
# @param delta: Delta time para decrementar cooldown
func _process_shooting(delta: float) -> void:
	# ETAPA 1: Sistema de cooldown
	# Decrementa timer e libera tiro quando chegar a zero
	if not can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0:
			can_shoot = true
	
	# ETAPA 2: Detecta input de disparo
	# is_mouse_button_pressed retorna true enquanto botão estiver segurado
	# Isso permite auto-fogo (múltiplos tiros segurando botão)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and can_shoot:
		_shoot()

# Cria e dispara um projétil na direção do mouse
# FLUXO:
# 1. Valida cena do projétil
# 2. Calcula direção para o cursor
# 3. Instancia e configura projétil
# 4. Adiciona à cena
# 5. Ativa cooldown
func _shoot() -> void:
	# VALIDAÇÃO: Verifica se cena do projétil foi configurada
	if not projectile_scene:
		push_warning("Projectile scene não configurado! Arraste a cena no Inspector.")
		return
	
	# ETAPA 1: Calcula direção do tiro
	var mouse_pos = get_global_mouse_position()  # Posição do cursor no mundo
	var shoot_direction = (mouse_pos - global_position).normalized()
	
	# ETAPA 2: Instancia o projétil
	var projectile = projectile_scene.instantiate()
	
	# ETAPA 3: Define posição inicial (mesma do herói)
	projectile.global_position = global_position
	
	# ETAPA 4: Configura direção do projétil
	# Tenta método set_direction() primeiro (preferível)
	if projectile.has_method("set_direction"):
		projectile.set_direction(shoot_direction)
	# Senão, define propriedade direction diretamente
	elif "direction" in projectile:
		projectile.direction = shoot_direction

	# ETAPA 5: Configura team do projétil
	# Marca como "player" para evitar acertar o próprio herói
	if projectile.has_method("set_team"):
		projectile.set_team("player")
	elif "team" in projectile:
		projectile.team = "player"
	
	# ETAPA 6: Aplica multiplicador de dano (upgrade)
	# Converte para int porque dano é sempre inteiro
	if "damage" in projectile:
		projectile.damage = int(projectile.damage * damage_multiplier)
	
	# ETAPA 7: Adiciona à cena principal
	get_tree().current_scene.add_child(projectile)
	
	# ETAPA 8: Ativa cooldown
	can_shoot = false
	# Multiplica por fire_rate_multiplier (valores menores = mais rápido)
	shoot_timer = FIRE_RATE * fire_rate_multiplier


# ==============================================================================
# SISTEMA DE DANO E SAÚDE
# ==============================================================================
# Gerencia vida do herói, feedback visual, cura e morte
# ==============================================================================

# Aplica dano ao herói
# @param amount: Quantidade de dano a receber
# FLUXO:
# 1. Reduz saúde
# 2. Atualiza barra de vida
# 3. Feedback visual (flash vermelho)
# 4. Verifica morte (health <= 0)
func take_damage(amount: int) -> void:
	# ETAPA 1: Reduz saúde
	current_health -= amount
	
	# ETAPA 2: Atualiza UI
	_update_health_bar()
	
	# ETAPA 3: Feedback visual
	_flash_hit()
	
	# ETAPA 4: Verifica morte
	if current_health <= 0:
		_die()

# Cura o herói (não pode exceder vida máxima)
# @param amount: Quantidade de vida a recuperar
func heal(amount: int) -> void:
	# Usa min() para garantir que não ultrapasse max_health
	current_health = min(current_health + amount, max_health)
	_update_health_bar()

# Adiciona um reroll ao contador
# Rerolls permitem recarregar opções de upgrade
func add_reroll() -> void:
	reroll_count += 1

# Atualiza a ProgressBar visual com saúde atual
func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health  # Valor máximo da barra
		health_bar.value = current_health  # Valor atual (cria preenchimento proporcional)

# Efeito visual de hit - pisca sprite em vermelho
# ANTI-SPAM: Flag is_hit previne múltiplos flashes simultâneos
func _flash_hit() -> void:
	# Validações: sprite existe e não está já no meio de outro flash
	if not sprite or is_hit:
		return
	
	# Marca que está no meio de um flash
	is_hit = true
	
	# Muda cor para vermelho
	sprite.modulate = Color.RED
	
	# Aguarda duração configurada
	await get_tree().create_timer(hit_flash_duration).timeout
	
	# Volta à cor normal (verifica se sprite ainda existe)
	if sprite:
		sprite.modulate = Color.WHITE
	
	# Libera flag para permitir próximo flash
	is_hit = false

# Morte do herói - mostra tela de game over
# FLUXO:
# 1. Carrega cena de game over
# 2. Adiciona à cena atual
# 3. Pausa o jogo
# 4. Remove o herói
func _die() -> void:
	# ETAPA 1: Carrega cena de game over
	var game_over_scene = load("res://rooms/game_over.tscn")
	
	if game_over_scene:
		# ETAPA 2: Instancia e adiciona à cena
		var game_over = game_over_scene.instantiate()
		get_tree().current_scene.add_child(game_over)
		
		# ETAPA 3: Pausa o jogo
		# get_tree().paused = true congela todos os nós com process_mode normal
		get_tree().paused = true
	
	# ETAPA 4: Remove o herói da cena
	queue_free()
