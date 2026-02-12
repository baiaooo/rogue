extends Area2D

# =========================
# CONFIGURAÇÕES DO PICKUP
# =========================
@export var heal_percent: float = 0.3  # Cura 30% da vida máxima
@export var color_1: Color = Color(0.0, 1.0, 0.3)  # Verde claro
@export var color_2: Color = Color(0.0, 0.6, 0.2)  # Verde escuro
@export var color_change_speed: float = 3.0
@export var bob_speed: float = 2.0  # Velocidade do "flutuar"
@export var bob_amount: float = 5.0  # Altura do movimento

# =========================
# VARIÁVEIS INTERNAS
# =========================
var color_time: float = 0.0
var bob_time: float = 0.0
var initial_y: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	initial_y = position.y
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_apply_color_change(delta)
	_apply_bobbing(delta)

# =========================
# EFEITOS VISUAIS
# =========================
func _apply_color_change(delta: float) -> void:
	if not sprite:
		return
	
	color_time += delta * color_change_speed
	var blend_factor = (sin(color_time) + 1.0) / 2.0
	var current_color = color_1.lerp(color_2, blend_factor)
	sprite.modulate = current_color

func _apply_bobbing(delta: float) -> void:
	bob_time += delta * bob_speed
	var offset = sin(bob_time) * bob_amount
	position.y = initial_y + offset

# =========================
# SISTEMA DE COLETA
# =========================
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	if body.has_method("heal"):
		# Calcula a cura baseada na vida máxima do player
		var heal_amount = 0
		if "max_health" in body:
			heal_amount = int(body.max_health * heal_percent)
		else:
			heal_amount = 30  # Fallback
		
		body.heal(heal_amount)
	
	queue_free()
