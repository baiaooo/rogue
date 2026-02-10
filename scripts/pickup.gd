extends Area2D

# ======================================
# SCRIPT DE PICKUP (REROLL / HEAL)
# ======================================
# Este script controla os dois tipos de pickup pedidos:
# - reroll: adiciona 1 reroll para a tela de boss
# - heal: cura instantânea de 30% da vida máxima
#
# Observação importante:
# o pickup de cura NÃO pode ser coletado com vida cheia.

@export var pickup_type: String = "reroll"

# Referência opcional ao sprite para mudar a cor por tipo.
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	# Conecta a colisão com corpos (herói é CharacterBody2D).
	body_entered.connect(_on_body_entered)

	# Atualiza visual para facilitar identificação em jogo.
	_update_visual()

func _update_visual() -> void:
	if not sprite:
		return

	# Reroll = azul/ciano, Heal = verde.
	if pickup_type == "reroll":
		sprite.modulate = Color(0.25, 0.85, 1.0)
	elif pickup_type == "heal":
		sprite.modulate = Color(0.4, 1.0, 0.4)

func _on_body_entered(body: Node) -> void:
	# Só o player pode interagir com pickup.
	if not body.is_in_group("player"):
		return

	# Heal só pode ser pego se NÃO estiver com vida cheia.
	if pickup_type == "heal" and body.has_method("is_full_health") and body.is_full_health():
		return

	# Dispara aplicação para a cena principal (forest.gd).
	# Isso evita acoplamento do pickup com detalhes internos do herói/UI.
	var scene := get_tree().current_scene
	if scene and scene.has_method("collect_pickup"):
		scene.collect_pickup(pickup_type, body)

	# Remove pickup após coleta válida.
	queue_free()
