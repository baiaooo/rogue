extends CanvasLayer

@onready var restart_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/RestartButton
@onready var menu_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/MenuButton

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://rooms/main_menu.tscn")
