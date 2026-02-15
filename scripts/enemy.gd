extends CharacterBody2D

signal died(enemy: Node, is_boss: bool)

# =========================
# DADOS DO INIMIGO (RESOURCE)
# =========================
@export var enemy_data: EnemyData

# =========================
# CONFIGURAÇÕES ÚNICAS DA INSTÂNCIA
# =========================
@export var speed: float = 30.0
@export var health: int = 100
@export var damage: int = 10
@export var is_boss: bool = false

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
# CONFIGURAÇÕES DE DROP (GLOBAIS)
# =========================
@export_group("Pickup Scenes")
@export var health_pickup_scene: PackedScene
@export var reroll_pickup_scene: PackedScene
@export_group("")
@export var drop_chance: float = 0.3  # 30% de chance de dropar
@export var health_drop_chance: float = 0.5  # 50% de ser health pickup

# =========================
# VARIÁVEIS INTERNAS
# =========================
var player: CharacterBody2D = null
var can_shoot: bool = true
var shoot_timer: float = 0.0
var is_hit: bool = false
var max_health: int = 0

# Referências aos nós
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var health_bar: ProgressBar = $HealthBar if has_node("HealthBar") else null

func _ready() -> void:
	# Carrega dados do resource se disponível
	if enemy_data:
		speed = enemy_data.speed
		health = enemy_data.health
		damage = enemy_data.damage
		shoot_range = enemy_data.shoot_range
		shoot_cooldown = enemy_data.shoot_cooldown
		stop_distance = enemy_data.stop_distance
		drop_chance = enemy_data.drop_chance
		health_drop_chance = enemy_data.health_drop_chance
		hit_flash_duration = enemy_data.hit_flash_duration
		
		# Aplica sprite se configurado
		if enemy_data.sprite_texture and sprite:
			sprite.texture = enemy_data.sprite_texture
			scale = Vector2(enemy_data.enemy_size, enemy_data.enemy_size)
		
		# Aplica projétil se configurado
		if enemy_data.projectile_scene:
			enemy_projectile_scene = enemy_data.projectile_scene
	
	add_to_group("enemy")
	max_health = health
	_update_health_bar()
	# Busca o player na cena (assumindo que tem o grupo "player")
	_find_player()
	
	# Carrega as cenas de pickup das configurações globais do autoload
	if not health_pickup_scene and GameGlobals.health_pickup_scene:
		health_pickup_scene = GameGlobals.health_pickup_scene
	if not reroll_pickup_scene and GameGlobals.reroll_pickup_scene:
		reroll_pickup_scene = GameGlobals.reroll_pickup_scene

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
	
	# Comportamento baseado no tipo
	var behavior_type = enemy_data.behavior if enemy_data else EnemyData.Behavior.CHASE_AND_SHOOT
	
	match behavior_type:
		EnemyData.Behavior.CHASE_AND_SHOOT:
			_behavior_chase_and_shoot(delta)
		EnemyData.Behavior.MELEE_ONLY:
			_behavior_melee_only(delta)
		EnemyData.Behavior.STATIONARY_SHOOTER:
			_behavior_stationary_shooter(delta)
	
	# Aplica o movimento
	move_and_slide()

func _behavior_chase_and_shoot(delta: float) -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Persegue o player se estiver longe
	if distance_to_player > stop_distance:
		_chase_player(delta)
	else:
		velocity = Vector2.ZERO
	
	# Atira se estiver dentro do alcance
	if distance_to_player <= shoot_range and can_shoot:
		_shoot_at_player()

func _behavior_melee_only(delta: float) -> void:
	# Sempre persegue, não atira
	_chase_player(delta)

func _behavior_stationary_shooter(delta: float) -> void:
	# Fica parado, apenas atira
	velocity = Vector2.ZERO
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player <= shoot_range and can_shoot:
		_shoot_at_player()

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
	_update_health_bar()
	
	# Efeito visual de hit
	_flash_hit()
	
	# Verifica se morreu
	if health <= 0:
		_die()

func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

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
	# Tenta dropar um pickup
	_try_drop_pickup()
	
	# Adicione aqui efeitos de morte (partículas, som, etc)
	died.emit(self, is_boss)
	queue_free()

func _try_drop_pickup() -> void:
	# Verifica se deve dropar
	if randf() > drop_chance:
		return
	
	# Escolhe o tipo de pickup baseado na chance
	var pickup_scene = health_pickup_scene if randf() < health_drop_chance else reroll_pickup_scene
	
	if not pickup_scene:
		print("Pickup scene não configurada! Health: ", health_pickup_scene != null, " Reroll: ", reroll_pickup_scene != null)
		return
	
	var pickup = pickup_scene.instantiate()
	pickup.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", pickup)
