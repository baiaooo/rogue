extends Area2D

# =========================
# CONFIGURAÇÕES DO PICKUP
# =========================
@export var color_1: Color = Color(1.0, 0.8, 0.0)  # Amarelo
@export var color_2: Color = Color(1.0, 0.4, 0.0)  # Laranja
@export var color_change_speed: float = 3.0
@export var bob_speed: float = 2.0  # Velocidade do "flutuar"
@export var bob_amount: float = 5.0  # Altura do movimento
@export var rotation_speed: float = 2.0  # Velocidade de rotação

# =========================
# VARIÁVEIS INTERNAS
# =========================
var color_time: float = 0.0
var bob_time: float = 0.0
var initial_y: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var pickup_name_label: Label = $PickupName if has_node("PickupName") else null

func _ready() -> void:
	initial_y = position.y
	if pickup_name_label:
		pickup_name_label.text = "Reroll"
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_apply_color_change(delta)
	_apply_bobbing(delta)
	_apply_rotation(delta)

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

func _apply_rotation(delta: float) -> void:
	if sprite:
		sprite.rotation += delta * rotation_speed

# =========================
# SISTEMA DE COLETA
# =========================
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	# Adiciona um reroll ao inventário do jogador
	if body.has_method("add_reroll"):
		body.add_reroll()
	elif "reroll_count" in body:
		body.reroll_count += 1
	
	queue_free()
