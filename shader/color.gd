extends ColorRect

@export var mode_follow_camera := true
# true  = padrão “grudado na câmera” (não deve mexer ao andar)
# false = padrão “grudado no mundo” (anda junto com o cenário)

@onready var mat := material as ShaderMaterial
var cam: Camera2D

func _ready() -> void:
	cam = get_viewport().get_camera_2d()
	if cam == null:
		push_error("Overlay CRT: nenhuma Camera2D current encontrada.")
		set_process(false)

func _process(_delta: float) -> void:
	# Centro da câmera em coordenadas de mundo (normalmente pixels em jogos 2D)
	var c := cam.get_screen_center_position()

	# Tamanho do viewport em pixels de tela
	var vp := get_viewport().get_visible_rect().size

	# Quantos “pixels de mundo” cabem na tela considerando o zoom
	# zoom > 1 = zoom in => menos mundo visível
	var world_visible := vp / cam.zoom

	# Converte posição da câmera (mundo) -> UV
	var offset_uv := Vector2(c.x, c.y) / world_visible

	# Se quiser “grudado no mundo”, inverte
	if not mode_follow_camera:
		offset_uv = -offset_uv

	mat.set_shader_parameter("pattern_offset", offset_uv)
