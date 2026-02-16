extends Node

# =========================
# CENAS DE PICKUP (GLOBAIS)
# =========================
var health_pickup_scene: PackedScene
var reroll_pickup_scene: PackedScene

# =========================
# GERENCIAMENTO DE FASES
# =========================
var available_levels: Array[PackedScene] = []
var current_level_data: LevelData = null
var current_level_number: int = 0

func _ready() -> void:
	# Carrega as cenas de pickup
	health_pickup_scene = load("res://pickups/health_pickup.tscn")
	reroll_pickup_scene = load("res://pickups/reroll_pickup.tscn")
	
	# Carrega as fases disponíveis
	available_levels = [
		load("res://rooms/forest.tscn"),
		load("res://rooms/beach.tscn")
	]

# =========================
# FUNÇÕES DE UTILIDADE
# =========================
func get_random_level() -> PackedScene:
	if available_levels.is_empty():
		return null
	return available_levels[randi() % available_levels.size()]

func get_next_level(from_level_data: LevelData = null) -> PackedScene:
	# Se tem dados de fase e próximas fases definidas
	if from_level_data and not from_level_data.next_levels.is_empty():
		return from_level_data.next_levels[randi() % from_level_data.next_levels.size()]
	
	# Caso contrário, retorna uma fase aleatória
	return get_random_level()

func start_new_run() -> void:
	current_level_number = 0

func advance_level_counter() -> int:
	current_level_number += 1
	return current_level_number
