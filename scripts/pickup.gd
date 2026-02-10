extends Area2D

# =========================
# TIPOS DE PICKUP
# =========================
@export_enum("reroll", "heal") var pickup_type: String = "reroll"

# Referência visual simples
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	# Grupo para facilitar debug e futuras interações
	add_to_group("pickup")
	body_entered.connect(_on_body_entered)
	_apply_visual()

func _apply_visual() -> void:
	# Diferencia visualmente os tipos de pickup por cor
	if not sprite:
		return
	
	if pickup_type == "heal":
		sprite.modulate = Color(0.3, 1.0, 0.3)
	else:
		sprite.modulate = Color(0.3, 0.8, 1.0)

func _on_body_entered(body: Node2D) -> void:
	# Apenas o jogador pode coletar
	if not body.is_in_group("player"):
		return
	
	# Aplica cada pickup com regras específicas
	if pickup_type == "heal":
		if body.has_method("heal_percent"):
			var healed: bool = body.heal_percent(0.30)
			# Se não conseguiu curar (vida cheia), não coleta
			if not healed:
				return
	elif pickup_type == "reroll":
		if body.has_method("add_reroll"):
			body.add_reroll(1)
	
	# Remove pickup após coleta bem-sucedida
	queue_free()
