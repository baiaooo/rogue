extends CharacterBody2D

# =========================
# CONFIGURAÇÕES DO INIMIGO
# =========================
@export var speed: float = 30.0
@export var health: int = 100
@export var damage: int = 10

# =========================
# CONFIGURAÇÕES DE COMBATE
# =========================
@export var enemy_projectile_scene: PackedScene  # Cena do projétil do inimigo
@export var shoot_range: float = 100.0  # Distância mínima para atirar
@export var shoot_cooldown: float = 1.5  # Tempo entre tiros
@export var stop_distance: float = 50.0  # Distância para parar de se aproximar

# =========================
# CONFIGURAÇÕES VISUAIS
# =========================
@export var hit_flash_duration: float = 0.1  # Duração do efeito de hit

# =========================
# VARIÁVEIS INTERNAS
# =========================
var player: CharacterBody2D = null
var can_shoot: bool = true
var shoot_timer: float = 0.0
var is_hit: bool = false

# Referências aos nós
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	add_to_group("enemy")
	# Busca o player na cena (assumindo que tem o grupo "player")
	_find_player()

func _physics_process(delta: float) -> void:
	# Atualiza o timer de tiro
	if not can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0:
			can_shoot = true
	
	# Se não encontrou o player, tenta encontrar
	if not player:
		_find_player()
		return
	
	# Calcula a distância até o player
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Persegue o player se estiver longe
	if distance_to_player > stop_distance:
		_chase_player(delta)
	else:
		# Para de se mover se estiver perto o suficiente
		velocity = Vector2.ZERO
	
	# Atira se estiver dentro do alcance
	if distance_to_player <= shoot_range and can_shoot:
		_shoot_at_player()
	
	# Aplica o movimento
	move_and_slide()

# =========================
# SISTEMA DE PERSEGUIÇÃO
# =========================
func _chase_player(delta: float) -> void:
	# Calcula a direção até o player
	var direction = (player.global_position - global_position).normalized()
	
	# Define a velocidade
	velocity = direction * speed
	
	# Opcional: Faz o sprite olhar para o player
	if sprite and velocity.length() > 0:
		# Vira o sprite baseado na direção horizontal
		sprite.flip_h = velocity.x < 0

func _find_player() -> void:
	# Tenta encontrar o player pelo grupo
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

# =========================
# SISTEMA DE DISPARO
# =========================
func _shoot_at_player() -> void:
	# Verifica se a cena do projétil foi configurada
	if not enemy_projectile_scene:
		return
	
	# Calcula a direção do tiro
	var shoot_direction = (player.global_position - global_position).normalized()
	
	# Instancia o projétil
	var projectile = enemy_projectile_scene.instantiate()

	if "speed" in projectile:
		projectile.speed = 300.0
	if "damage" in projectile:
		projectile.damage = 15
	if "lifetime" in projectile:
		projectile.lifetime = 5.0
	if "color_1" in projectile:
		projectile.color_1 = Color(1.0, 0.3, 0.0)
	if "color_2" in projectile:
		projectile.color_2 = Color(0.8, 0.0, 0.0)
	if "color_change_speed" in projectile:
		projectile.color_change_speed = 8.0
	
	# Configura a posição inicial
	projectile.global_position = global_position
	
	# Configura a direção
	if projectile.has_method("set_direction"):
		projectile.set_direction(shoot_direction)
	elif "direction" in projectile:
		projectile.direction = shoot_direction
	
	# Marca o projétil como do inimigo (para não atingir outros inimigos)
	if projectile.has_method("set_team"):
		projectile.set_team("enemy")
	elif "team" in projectile:
		projectile.team = "enemy"
	
	# Adiciona à cena
	get_tree().current_scene.add_child(projectile)
	
	# Reseta o cooldown
	can_shoot = false
	shoot_timer = shoot_cooldown

# =========================
# SISTEMA DE DANO
# =========================
func take_damage(amount: int) -> void:
	health -= amount
	
	# Efeito visual de hit
	_flash_hit()
	
	# Verifica se morreu
	if health <= 0:
		_die()

func _flash_hit() -> void:
	if not sprite or is_hit:
		return
	
	is_hit = true
	sprite.modulate = Color.RED
	
	# Volta à cor normal após um tempo
	await get_tree().create_timer(hit_flash_duration).timeout
	
	if sprite:  # Verifica se ainda existe
		sprite.modulate = Color.WHITE
	is_hit = false

func _die() -> void:
	# Adicione aqui efeitos de morte (partículas, som, etc)
	queue_free()
