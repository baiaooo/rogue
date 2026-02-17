# ==============================================================================
# GAME_GLOBALS.GD - Autoload Singleton de Estado Global
# ==============================================================================
# Este script é um autoload (singleton) que persiste entre cenas
# FUNCIONALIDADES:
# - Armazena referências a cenas de pickups (health, reroll)
# - Gerencia lista de fases disponíveis no jogo
# - Rastreia qual fase atual e contador de nível
# - Fornece funções utilitárias para seleção de próxima fase
#
# AUTOLOAD:
# Este script é configurado como autoload no Project Settings
# Nome do autoload: "GameGlobals"
# Acessível globalmente via: GameGlobals.variavel ou GameGlobals.funcao()
#
# USO TÍPICO:
# - Inimigos acessam GameGlobals.health_pickup_scene para dropar pickups
# - LevelManager usa get_next_level() para transicionar entre fases
# - LevelManager chama advance_level_counter() ao iniciar cada fase
# ==============================================================================

extends Node

# =========================
# CENAS DE PICKUP (GLOBAIS)
# =========================
# Referências carregadas das cenas de pickup
# Usadas como fallback quando inimigos não têm cenas configuradas diretamente

# Cena do pickup de cura (coração verde que restaura vida)
var health_pickup_scene: PackedScene

# Cena do pickup de reroll (estrela amarela que adiciona reroll)
var reroll_pickup_scene: PackedScene

# =========================
# GERENCIAMENTO DE FASES
# =========================
# Lista de todas as cenas de fases disponíveis no jogo
# Usado para seleção aleatória de próxima fase
var available_levels: Array[PackedScene] = []

# Referência ao LevelData resource da fase atual
# Armazenado pelo LevelManager no _ready()
# Usado para acessar configurações de próximas fases
var current_level_data: LevelData = null

# Contador de fases completadas na run atual
# Incrementado toda vez que uma nova fase é carregada
# Usado para exibir "Nível X" na UI
var current_level_number: int = 0


# ==============================================================================
# INICIALIZAÇÃO
# ==============================================================================
# Chamado quando o autoload é instanciado (antes de qualquer cena carregar)
# FLUXO:
# 1. Carrega cenas de pickups
# 2. Inicializa lista de fases disponíveis
# ==============================================================================
func _ready() -> void:
	# ETAPA 1: Carrega cenas de pickups
	# Estas cenas são usadas como fallback por todos os inimigos
	health_pickup_scene = load("res://pickups/health_pickup.tscn")
	reroll_pickup_scene = load("res://pickups/reroll_pickup.tscn")
	
	# ETAPA 2: Carrega lista de fases disponíveis
	# A ordem não importa pois seleção é aleatória
	available_levels = [
		load("res://rooms/forest.tscn"),  # Fase da floresta
		load("res://rooms/beach.tscn")    # Fase da praia
	]


# ==============================================================================
# FUNÇÕES DE UTILIDADE
# ==============================================================================
# Funções auxiliares para gerenciar progressão de fases
# ==============================================================================

# Retorna uma fase aleatória da lista de fases disponíveis
# @return: PackedScene de uma fase, ou null se lista vazia
func get_random_level() -> PackedScene:
	# VALIDAÇÃO: Verifica se há fases disponíveis
	if available_levels.is_empty():
		return null
	
	# Seleciona índice aleatório usando módulo
	# randi() retorna int aleatório
	# % size() garante índice válido (0 a size-1)
	return available_levels[randi() % available_levels.size()]


# Retorna a próxima fase baseada nos dados da fase atual
# @param from_level_data: LevelData resource da fase atual (opcional)
# @return: PackedScene da próxima fase
# LÓGICA:
# 1. Se from_level_data tem next_levels configurados: usa um deles aleatoriamente
# 2. Caso contrário: usa get_random_level() (qualquer fase disponível)
func get_next_level(from_level_data: LevelData = null) -> PackedScene:
	# OPÇÃO 1: Usa next_levels do LevelData se disponível
	# Isso permite criar progressões específicas (ex: floresta → praia → caverna)
	if from_level_data and not from_level_data.next_levels.is_empty():
		# Seleciona aleatoriamente entre as próximas fases configuradas
		return from_level_data.next_levels[randi() % from_level_data.next_levels.size()]
	
	# OPÇÃO 2: Fallback para fase completamente aleatória
	# Usado quando LevelData não tem next_levels configurados
	return get_random_level()


# Reinicia o contador de fases para uma nova run
# Chamado no menu principal ou ao iniciar novo jogo
func start_new_run() -> void:
	current_level_number = 0


# Incrementa e retorna o contador de fases
# Chamado pelo LevelManager no _ready() de cada fase
# @return: Número da fase atual (após incremento)
func advance_level_counter() -> int:
	current_level_number += 1
	return current_level_number
