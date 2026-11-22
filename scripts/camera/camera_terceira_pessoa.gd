class_name CameraTerceiraPessoa
extends Node3D
## Câmera em 3ª pessoa: gira em volta do alvo com o mouse e fica atrás dele.
## O braço (SpringArm3D) encurta sozinho quando algo fica entre a câmera e o alvo.

@export var alvo: Node3D
@export var altura_do_foco := 1.6
@export var distancia := 4.6
@export var sensibilidade := 0.003
@export var capturar_mouse := true

var yaw := 0.0
var pitch := -0.2

@onready var braco: SpringArm3D = $Braco


func _ready() -> void:
	braco.spring_length = distancia
	var esfera := SphereShape3D.new()   # a câmera tem corpo: não encosta a menos de 30 cm de parede nem de teto
	esfera.radius = 0.3
	braco.shape = esfera
	braco.collision_mask = 3   # camada 1 (mundo) e camada 2 (tetos das casas, que só a câmera enxerga)
	braco.margin = 0.05
	var lente := braco.get_node_or_null("Lente") as Camera3D
	if lente:
		lente.near = 0.05
	if alvo is CollisionObject3D:
		braco.add_excluded_object(alvo.get_rid())
	if capturar_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= evento.relative.x * sensibilidade
		pitch = clamp(pitch - evento.relative.y * sensibilidade, -1.0, 0.4)
	elif evento is InputEventKey and evento.pressed and evento.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif evento is InputEventMouseButton and evento.pressed and capturar_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_delta: float) -> void:
	if alvo == null:
		return
	global_position = alvo.global_position + Vector3(0.0, altura_do_foco, 0.0)
	rotation = Vector3(pitch, yaw, 0.0)
