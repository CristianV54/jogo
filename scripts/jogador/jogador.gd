class_name Jogador
extends CharacterBody3D
## Corpo do jogador (Torin): anda e corre em relação à direção da câmera (WASD, Shift).
## O visual é o Torin real; o modelo olha para +Z, então o nó Visual fica girado 180° para olhar para a frente do jogador (-Z).
## A entrada pode ser forçada por código, só para os testes automáticos.

@export var camera: CameraTerceiraPessoa
@export var velocidade_andando := 4.0
@export var velocidade_correndo := 7.0
@export var gravidade := 20.0
@export var giro := 10.0

var entrada_forcada := Vector2.ZERO   # x: direita(+), y: trás(+). Zero = usa o teclado.
var correndo_forcado := false
var animacao_atual := ""

@onready var visual: Humanoide = $Visual


func _physics_process(delta: float) -> void:
	var entrada := _ler_entrada()
	var correndo := correndo_forcado or Input.is_physical_key_pressed(KEY_SHIFT)
	var yaw := camera.yaw if camera else 0.0
	var direcao := Vector3(entrada.x, 0.0, entrada.y).rotated(Vector3.UP, yaw)
	var velocidade := velocidade_correndo if correndo else velocidade_andando

	velocity.x = direcao.x * velocidade
	velocity.z = direcao.z * velocidade
	velocity.y = 0.0 if is_on_floor() else velocity.y - gravidade * delta
	move_and_slide()

	if direcao.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direcao.x, -direcao.z), giro * delta)
	_animar(direcao.length(), correndo)


func _animar(movimento: float, correndo: bool) -> void:
	var nome := "Idle"
	if not is_on_floor():
		nome = "Jump"
	elif movimento > 0.01:
		nome = "Sprint" if correndo else "Jog_Fwd"
	if nome != animacao_atual:
		visual.tocar(nome)
		animacao_atual = nome


func _ler_entrada() -> Vector2:
	if entrada_forcada != Vector2.ZERO:
		return entrada_forcada.limit_length(1.0)
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		v.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		v.x += 1.0
	return v.limit_length(1.0)
