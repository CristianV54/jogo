class_name CameraTerceiraPessoa
extends Node3D
## Câmera em 3ª pessoa: gira em volta do alvo com o mouse e fica atrás dele.
## O braço (SpringArm3D) encurta sozinho quando algo fica entre a câmera e o alvo.

@export var alvo: Node3D
@export var altura_do_foco := 1.5
@export var distancia := 6.0
@export var sensibilidade := 0.003
@export var capturar_mouse := true

var yaw := 0.0
var pitch := -0.25

@onready var braco: SpringArm3D = $Braco


func _ready() -> void:
	braco.spring_length = distancia
	if alvo is CollisionObject3D:
		braco.add_excluded_object(alvo.get_rid())
	if capturar_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= evento.relative.x * sensibilidade
		pitch = clamp(pitch - evento.relative.y * sensibilidade, -1.2, 0.5)
	elif evento is InputEventKey and evento.pressed and evento.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif evento is InputEventMouseButton and evento.pressed and capturar_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_delta: float) -> void:
	if alvo == null:
		return
	global_position = alvo.global_position + Vector3(0.0, altura_do_foco, 0.0)
	rotation = Vector3(pitch, yaw, 0.0)
