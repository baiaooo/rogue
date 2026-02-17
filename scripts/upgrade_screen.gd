extends CanvasLayer

signal upgrade_selected
signal reroll_pressed

# =========================
# CONFIGURAÇÕES
# =========================
@export var upgrade_options_count: int = 3

# =========================
# REFERÊNCIAS UI
# =========================
@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBox/Title
@onready var options_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBox/OptionsContainer
@onready var reroll_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/RerollButton

# =========================
# VARIÁVEIS
# =========================
var player: Node = null
var available_upgrades: Array[Dictionary] = []
var current_options: Array[Dictionary] = []

# Lista de upgrades possíveis
var upgrade_pool: Array[Dictionary] = [
	{
		"name": "Vida Máxima +20",
		"description": "Aumenta sua vida máxima em 20 pontos",
		"icon": "❤️",
		"apply": func(p): 
			p.max_health += 20
			p.current_health += 20
			p._update_health_bar()},
	{
		"name": "Velocidade +20%",
		"description": "Aumenta sua velocidade de movimento",
		"icon": "⚡",
		"apply": func(p):
			p.speed_multiplier += 0.2},
	{
		"name": "Taxa de Tiro +30%",
		"description": "Atire mais rápido",
		"icon": "🔫",
		"apply": func(p):
			p.fire_rate_multiplier *= 0.7},
	{
		"name": "Dano +25%",
		"description": "Seus projéteis causam mais dano",
		"icon": "💥",
		"apply": func(p):
			p.damage_multiplier += 0.25},
	{
		"name": "Cura Completa",
		"description": "Restaura toda sua vida",
		"icon": "✨",
		"apply": func(p):
			p.current_health = p.max_health
			p._update_health_bar()},
	{
		"name": "Dash Melhorado",
		"description": "Dash mais rápido e mais longo",
		"icon": "💨",
		"apply": func(p):
			p.dash_speed_bonus += 50
			p.dash_duration_bonus += 0.1},
]

func _ready() -> void:
	hide()
	_setup_signals()

func _setup_signals() -> void:
	if reroll_button:
		reroll_button.pressed.connect(_on_reroll_pressed)

func show_upgrades(p: Node) -> void:
	player = p
	_generate_options()
	_update_reroll_button()
	show()

func _generate_options() -> void:
	# Limpa opções antigas
	for child in options_container.get_children():
		child.queue_free()
	
	current_options.clear()
	
	# Escolhe upgrades aleatórios
	var pool = upgrade_pool.duplicate()
	pool.shuffle()
	
	for i in range(min(upgrade_options_count, pool.size())):
		var upgrade = pool[i]
		current_options.append(upgrade)
		_create_upgrade_button(upgrade, i)

func _create_upgrade_button(upgrade: Dictionary, index: int) -> void:
	# Cria um container vertical para título + botão
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	
	# Adiciona o título
	var option_title = Label.new()
	option_title.text = upgrade.icon + " " + upgrade.name
	option_title.add_theme_font_size_override("font_size", 22)
	option_title.add_theme_color_override("font_color", Color(1, 0.9, 0))
	option_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(option_title)
	
	# Cria o botão com apenas a descrição
	var button = Button.new()
	button.custom_minimum_size = Vector2(500, 70)
	button.text = upgrade.description
	button.add_theme_font_size_override("font_size", 16)
	
	# Conecta o sinal
	button.pressed.connect(_on_upgrade_selected.bind(index))
	
	container.add_child(button)
	options_container.add_child(container)

func _on_upgrade_selected(index: int) -> void:
	if index >= current_options.size():
		return
	
	var upgrade = current_options[index]
	
	# Aplica o upgrade
	if upgrade.has("apply") and player:
		upgrade.apply.call(player)
	
	emit_signal("upgrade_selected")
	hide()

func _on_reroll_pressed() -> void:
	if not player or not "reroll_count" in player:
		return
	
	if player.reroll_count <= 0:
		return
	
	player.reroll_count -= 1
	_generate_options()
	_update_reroll_button()
	emit_signal("reroll_pressed")

func _update_reroll_button() -> void:
	if not reroll_button or not player:
		return
	
	var count = player.reroll_count if "reroll_count" in player else 0
	reroll_button.text = "🔄 Reroll (%d)" % count
	reroll_button.disabled = count <= 0
