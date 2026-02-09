extends Area2D

# =========================
# CONFIGURAÇÕES DO PROJÉTIL
# =========================
@export var speed: float = 400.0
@export var lifetime: float = 3.0  # Tempo antes de destruir automaticamente
@export var damage: int = 20

# =========================
# CONFIGURAÇÕES DE COR
# =========================
@export var color_1: Color = Color.RED  # Primeira cor
@export var color_2: Color = Color.YELLOW  # Segunda cor
@export var color_change_speed: float = 5.0  # Velocidade da transição de cor

# =========================
# VARIÁVEIS INTERNAS
# =========================
var direction: Vector2 = Vector2.RIGHT
var color_time: float = 0.0

# Referência ao sprite (ajuste o caminho se necessário)
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	# Autodestruição após um tempo
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Move o projétil na direção configurada
	position += direction * speed * delta
	
	# Aplica a mudança de cor
	_apply_color_change(delta)

# =========================
# SISTEMA DE MUDANÇA DE COR
# =========================
func _apply_color_change(delta: float) -> void:
	if not sprite:
		return
	
	# Incrementa o tempo de mudança de cor
	color_time += delta * color_change_speed
	
	# Calcula o fator de interpolação usando seno (oscila entre 0 e 1)
	var blend_factor = (sin(color_time) + 1.0) / 2.0
	
	# Interpola entre as duas cores
	var current_color = color_1.lerp(color_2, blend_factor)
	
	# Aplica a cor ao sprite
	sprite.modulate = current_color

# =========================
# CONFIGURAÇÃO DE DIREÇÃO
# =========================
func set_direction(dir: Vector2) -> void:
	# Configura a direção do projétil
	direction = dir.normalized()
	
	# Rotaciona o sprite para apontar na direção do movimento
	rotation = direction.angle()

# =========================
# SISTEMA DE COLISÃO
# =========================
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif body.is_in_group("player"):
		return
	else:
		queue_free()
