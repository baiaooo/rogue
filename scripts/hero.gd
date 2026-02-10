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
@export var move_speed: float = 100.0
@export var dash_speed: float = 300.0
@export var dash_duration: float = 0.2

# =========================
# STATS DE DISPARO
# =========================
@export var projectile_scene: PackedScene
@export var fire_rate: float = 0.15
@export var projectile_damage_multiplier: float = 1.0

# =========================
# VARIÁVEIS DE WOBBLE (ROTAÇÃO)
# =========================
const WOBBLE_SPEED: float = 10.0
const WOBBLE_AMOUNT: float = 15.0

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

@onready var sprite: Node2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	if sprite:
		original_rotation = sprite.rotation

func _physics_process(delta: float) -> void:
	if controller_id != 1:
		return

	if is_dashing:
		_process_dash(delta)
	else:
		_process_movement(delta)

	_process_shooting(delta)
	move_and_slide()

func _process_movement(delta: float) -> void:
	var dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	if dir != Vector2.ZERO:
		dir = dir.normalized()

	velocity = dir * move_speed

	if velocity.length() > 0:
		_apply_wobble(delta)
	else:
		_reset_wobble()

	if Input.is_action_just_pressed("ui_accept"):
		_start_dash(dir if dir != Vector2.ZERO else Vector2.RIGHT)

func _start_dash(direction: Vector2) -> void:
	is_dashing = true
	dash_direction = direction.normalized()
	dash_timer = dash_duration

func _process_dash(delta: float) -> void:
	dash_timer -= delta

	if dash_timer <= 0:
		is_dashing = false
		velocity = Vector2.ZERO
	else:
		velocity = dash_direction * dash_speed

func _apply_wobble(delta: float) -> void:
	if not sprite:
		return

	wobble_time += delta * WOBBLE_SPEED
	var wobble_rotation := sin(wobble_time) * deg_to_rad(WOBBLE_AMOUNT)
	sprite.rotation = original_rotation + wobble_rotation

func _reset_wobble() -> void:
	if not sprite:
		return

	sprite.rotation = original_rotation
	wobble_time = 0.0

func _process_shooting(delta: float) -> void:
	if not can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0:
			can_shoot = true

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and can_shoot:
		_shoot()

func _shoot() -> void:
	if not projectile_scene:
		push_warning("Projectile scene não configurado! Arraste a cena no Inspector.")
		return

	var mouse_pos := get_global_mouse_position()
	var shoot_direction := (mouse_pos - global_position).normalized()
	var projectile = projectile_scene.instantiate()

	projectile.global_position = global_position

	if projectile.has_method("set_direction"):
		projectile.set_direction(shoot_direction)
	elif "direction" in projectile:
		projectile.direction = shoot_direction

	if projectile.has_method("set_team"):
		projectile.set_team("player")
	elif "team" in projectile:
		projectile.team = "player"

	# Aplica dano com multiplicador de upgrades do herói.
	if "damage" in projectile:
		projectile.damage = int(projectile.damage * projectile_damage_multiplier)

	get_tree().current_scene.add_child(projectile)

	can_shoot = false
	shoot_timer = fire_rate

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

# =========================
# UTILITÁRIOS PARA PICKUPS/UPGRADES
# =========================
func heal_by_percent(percent: float) -> void:
	# Cura proporcional à vida máxima, conforme pedido (30% no pickup).
	var heal_amount := int(max_health * percent)
	current_health = min(max_health, current_health + heal_amount)

func is_full_health() -> bool:
	return current_health >= max_health

func apply_upgrade(upgrade_id: String) -> void:
	# Upgrades simples para o loop após boss.
	if upgrade_id == "max_health_up":
		max_health += 20
		current_health = min(max_health, current_health + 20)
	elif upgrade_id == "move_speed_up":
		move_speed *= 1.15
	elif upgrade_id == "fire_rate_up":
		# Menor valor = mais tiros por segundo.
		fire_rate = max(0.05, fire_rate * 0.85)
	elif upgrade_id == "damage_up":
		projectile_damage_multiplier *= 1.2
