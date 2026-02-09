extends CharacterBody2D

# =========================
# VARIÁVEIS DE JOGADOR
# =========================
@export var controller_id: int = 1
# =========================
# STATS DE VIDA
# =========================
@export var max_health: int = 100
@export var current_health: int = 100
@export var hit_flash_duration: float = 0.1
# =========================
# STATS DE MOVIMENTO
# =========================
const SPEED: int = 100
const DASH_SPEED: int = 300
const DASH_DURATION: float = 0.2
# =========================
# STATS DE DISPARO
# =========================
@export var projectile_scene: PackedScene  # Arraste a cena do projétil aqui no Inspector
const FIRE_RATE: float = 0.15  # Tempo entre cada tiro (em segundos)
# =========================
# VARIÁVEIS DE WOBBLE (ROTAÇÃO)
# =========================
const WOBBLE_SPEED: float = 10.0  # Velocidade da oscilação
const WOBBLE_AMOUNT: float = 15.0  # Intensidade da rotação em graus
# =========================
# VARIÁVEIS INTERNAS
# =========================
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0
var can_shoot: bool = true
var shoot_timer: float = 0.0
var wobble_time: float = 0.0
var original_rotation: float = 0.0
var is_hit: bool = false

# Referência ao sprite (ajuste o caminho se necessário)
@onready var sprite: Node2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	# Salva a rotação original do sprite para o efeito wobble
	if sprite:
		original_rotation = sprite.rotation

func _physics_process(delta: float) -> void:
	# Verifica se este é o controlador ativo
	if controller_id != 1:
		return
	
	# Atualiza o timer de dash
	if is_dashing:
		_process_dash(delta)
	else:
		_process_movement(delta)
	
	# Sistema de disparo
	_process_shooting(delta)
	
	# Aplica o movimento
	move_and_slide()

# =========================
# MOVIMENTO NORMAL
# =========================
func _process_movement(delta: float) -> void:
	# Captura a direção do input
	var dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	
	# Normaliza a direção para movimento uniforme em diagonais
	if dir != Vector2.ZERO:
		dir = dir.normalized()
	
	# Define a velocidade
	velocity = dir * SPEED
	
	# Aplica o efeito wobble se estiver se movendo
	if velocity.length() > 0:
		_apply_wobble(delta)
	else:
		_reset_wobble()
	
	# Detecta input de dash
	if Input.is_action_just_pressed("ui_accept"):  # Tecla espaço
		_start_dash(dir if dir != Vector2.ZERO else Vector2.RIGHT)

# =========================
# SISTEMA DE DASH
# =========================
func _start_dash(direction: Vector2) -> void:
	# Inicia o dash na direção especificada
	is_dashing = true
	dash_direction = direction.normalized()
	dash_timer = DASH_DURATION

func _process_dash(delta: float) -> void:
	# Atualiza o timer do dash
	dash_timer -= delta
	
	if dash_timer <= 0:
		# Dash terminou
		is_dashing = false
		velocity = Vector2.ZERO
	else:
		# Mantém a velocidade do dash
		velocity = dash_direction * DASH_SPEED

# =========================
# EFEITO WOBBLE (ROTAÇÃO)
# =========================
func _apply_wobble(delta: float) -> void:
	if not sprite:
		return
	
	# Incrementa o tempo de wobble
	wobble_time += delta * WOBBLE_SPEED
	
	# Calcula a rotação usando seno (oscila entre -1 e 1)
	var wobble_rotation = sin(wobble_time) * deg_to_rad(WOBBLE_AMOUNT)
	
	# Aplica a rotação ao sprite
	sprite.rotation = original_rotation + wobble_rotation

func _reset_wobble() -> void:
	if not sprite:
		return
	
	# Reseta o sprite para a rotação original quando parado
	sprite.rotation = original_rotation
	wobble_time = 0.0

# =========================
# SISTEMA DE DISPARO
# =========================
func _process_shooting(delta: float) -> void:
	# Atualiza o timer de recarga do tiro
	if not can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0:
			can_shoot = true
	
	# Verifica se o mouse está sendo segurado
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and can_shoot:
		_shoot()

func _shoot() -> void:
	# Verifica se a cena do projétil foi configurada
	if not projectile_scene:
		push_warning("Projectile scene não configurado! Arraste a cena no Inspector.")
		return
	
	# Calcula a direção do mouse
	var mouse_pos = get_global_mouse_position()
	var shoot_direction = (mouse_pos - global_position).normalized()
	
	# Instancia o projétil
	var projectile = projectile_scene.instantiate()
	
	# Configura a posição inicial do projétil
	projectile.global_position = global_position
	
	# Configura a direção do projétil (assumindo que o projétil tem uma propriedade 'direction')
	if projectile.has_method("set_direction"):
		projectile.set_direction(shoot_direction)
	elif "direction" in projectile:
		projectile.direction = shoot_direction
	
	# Adiciona o projétil à cena
	get_tree().current_scene.add_child(projectile)
	
	# Reseta o timer de recarga
	can_shoot = false
	shoot_timer = FIRE_RATE
	
# E adicione a função de dano:
func take_damage(amount: int) -> void:
	current_health -= amount
	_flash_hit()
	
	if current_health <= 0:
		_die()

func _flash_hit() -> void:
	if not sprite or is_hit:
		return
	
	is_hit = true
	sprite.modulate = Color.RED
	
	await get_tree().create_timer(hit_flash_duration).timeout
	
	if sprite:
		sprite.modulate = Color.WHITE
	is_hit = false

func _die() -> void:
	queue_free()
