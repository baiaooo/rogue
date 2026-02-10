extends CharacterBody2D

signal died(enemy: Node, is_boss: bool)

# =========================
# CONFIGURAÇÕES BÁSICAS
# =========================
@export var health: int = 50
@export var damage: int = 10
@export var speed: float = 70.0
@export var enemy_projectile_scene: PackedScene
@export var shoot_range: float = 190.0
@export var shoot_cooldown: float = 1.0
@export var stop_distance: float = 50.0

# =========================
# CONFIGURAÇÕES VISUAIS
# =========================
@export var hit_flash_duration: float = 0.1

# =========================
# FLAGS/ESTADO
# =========================
var is_boss: bool = false
var player: CharacterBody2D = null
var can_shoot: bool = true
var shoot_timer: float = 0.0
var is_hit: bool = false

# Guardamos os valores base para poder aplicar modificadores de boss
# sempre partindo de um estado previsível.
var base_health: int = 50
var base_damage: int = 10
var base_speed: float = 70.0
var base_shoot_cooldown: float = 1.0

# Referências aos nós
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	add_to_group("enemy")
	_capture_base_stats()
	_find_player()

func _physics_process(delta: float) -> void:
	# Atualiza cooldown de tiro.
	if not can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0:
			can_shoot = true

	# Rebusca player se referência foi perdida.
	if not player:
		_find_player()
		return

	# Distância para decidir perseguir/parar/atirar.
	var distance_to_player := global_position.distance_to(player.global_position)

	if distance_to_player > stop_distance:
		_chase_player()
	else:
		velocity = Vector2.ZERO

	if distance_to_player <= shoot_range and can_shoot:
		_shoot_at_player()

	move_and_slide()

func _capture_base_stats() -> void:
	# Registra os valores originais da instância para referência.
	base_health = health
	base_damage = damage
	base_speed = speed
	base_shoot_cooldown = shoot_cooldown

func configure_as_boss(characteristic: String) -> void:
	# Aplica característica do boss antes dos multiplicadores finais de loop.
	# As 3 possibilidades são: giant, fast e ranger.
	if characteristic == "giant":
		health = int(health * 1.9)
		scale = Vector2(1.8, 1.8)
	elif characteristic == "fast":
		speed *= 1.6
		scale = Vector2(1.45, 1.45)
	elif characteristic == "ranger":
		shoot_cooldown *= 0.55
		scale = Vector2(1.45, 1.45)

func _chase_player() -> void:
	var direction := (player.global_position - global_position).normalized()
	velocity = direction * speed

	if sprite and velocity.length() > 0:
		sprite.flip_h = velocity.x < 0

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _shoot_at_player() -> void:
	if not enemy_projectile_scene:
		return

	var shoot_direction := (player.global_position - global_position).normalized()
	var projectile = enemy_projectile_scene.instantiate()

	# Configuração de projétil inimigo.
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

	projectile.global_position = global_position

	if projectile.has_method("set_direction"):
		projectile.set_direction(shoot_direction)
	elif "direction" in projectile:
		projectile.direction = shoot_direction

	if projectile.has_method("set_team"):
		projectile.set_team("enemy")
	elif "team" in projectile:
		projectile.team = "enemy"

	get_tree().current_scene.add_child(projectile)

	can_shoot = false
	shoot_timer = shoot_cooldown

func take_damage(amount: int) -> void:
	health -= amount
	_flash_hit()

	if health <= 0:
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
	died.emit(self, is_boss)
	queue_free()
