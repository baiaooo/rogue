extends Area2D

# =========================
# CONFIGURAÇÕES DO PROJÉTIL
# =========================
@export var speed: float = 300.0
@export var damage: int = 15
@export var lifetime: float = 5.0

# =========================
# CONFIGURAÇÕES DE COR
# =========================
@export var color_1: Color = Color(1.0, 0.3, 0.0)  # Laranja
@export var color_2: Color = Color(0.8, 0.0, 0.0)  # Vermelho escuro
@export var color_change_speed: float = 8.0

# =========================
# VARIÁVEIS INTERNAS
# =========================
var direction: Vector2 = Vector2.RIGHT
var team: String = "enemy"  # Para identificar de quem é o projétil
var color_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	# Autodestruição após tempo
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Move o projétil
	position += direction * speed * delta
	
	# Aplica mudança de cor
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
# CONFIGURAÇÃO
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
	# Só atinge o player, não outros inimigos
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	# Ignora inimigos
	elif body.is_in_group("enemy"):
		return
	# Colide com paredes/obstáculos
	else:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Opcional: colisão com outras áreas
	queue_free()
