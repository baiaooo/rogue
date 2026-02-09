extends Area2D

# =========================
# CONFIGURAÇÕES DO PROJÉTIL
# =========================
@export var speed: float = 400.0
@export var lifetime: float = 3.0
@export var damage: int = 20
@export var team: String = "player"

# =========================
# CONFIGURAÇÕES DE COR
# =========================
@export var color_1: Color = Color.RED
@export var color_2: Color = Color.YELLOW
@export var color_change_speed: float = 5.0

# =========================
# VARIÁVEIS INTERNAS
# =========================
var direction: Vector2 = Vector2.RIGHT
var color_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	if lifetime > 0:
		await get_tree().create_timer(lifetime).timeout
		queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_apply_color_change(delta)

# =========================
# SISTEMA DE MUDANÇA DE COR
# =========================
func _apply_color_change(delta: float) -> void:
	if not sprite:
		return

	color_time += delta * color_change_speed
	var blend_factor = (sin(color_time) + 1.0) / 2.0
	var current_color = color_1.lerp(color_2, blend_factor)
	sprite.modulate = current_color

# =========================
# CONFIGURAÇÃO DE DIREÇÃO/TIME
# =========================
func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()

func set_team(team_name: String) -> void:
	team = team_name

# =========================
# SISTEMA DE COLISÃO
# =========================
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(team):
		return

	var target_group := team == "enemy" ? "player" : "enemy"
	if body.is_in_group(target_group):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
		return

	queue_free()

func _on_area_entered(area: Area2D) -> void:
	queue_free()
