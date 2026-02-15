extends Area2D

signal flag_touched

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

var bob_time: float = 0.0
const BOB_SPEED: float = 3.0
const BOB_AMOUNT: float = 10.0
var initial_y: float = 0.0

func _ready() -> void:
	add_to_group("flag")
	initial_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Efeito de flutuação
	bob_time += delta * BOB_SPEED
	if sprite:
		sprite.position.y = sin(bob_time) * BOB_AMOUNT

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		emit_signal("flag_touched")
		queue_free()
