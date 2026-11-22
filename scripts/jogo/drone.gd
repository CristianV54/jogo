class_name Drone
extends Node3D
## Drone de auditoria: uma câmera livre que não depende do Torin (sem vida, arma, montaria nem colisão). Voa a qualquer
## altura, atravessa tudo e vai a qualquer coordenada. Serve para olhar o mundo inteiro de cima e de perto. Quando ligado, o
## Torin fica parado e travado; ao desligar, a câmera do jogo volta.
##   WASD anda, Espaço sobe, C desce, Shift acelera, mouse gira, Ctrl devagar.

const VEL := 40.0
const VEL_RAPIDA := 220.0
const VEL_LENTA := 8.0

var camera: Camera3D
var ligado := false
var _yaw := 0.0
var _pitch := -0.5
var _camera_do_jogo: Camera3D
var _mouse_antes := Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	name = "Drone"
	camera = Camera3D.new()
	camera.far = 5000.0
	camera.fov = 70.0
	add_child(camera)
	set_process(false)
	set_process_unhandled_input(false)


func ligar(jogo: Node, posicao: Vector3) -> void:
	_camera_do_jogo = jogo.get("camera") as Camera3D
	global_position = posicao
	_yaw = 0.0
	_pitch = -0.5
	ligado = true
	var jog := jogo.get("jogador") as Jogador
	if jog:
		jog.travado = true
		jog.velocity = Vector3.ZERO
	camera.current = true
	_mouse_antes = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_process(true)
	set_process_unhandled_input(true)
	_aplicar()


func desligar(jogo: Node) -> void:
	ligado = false
	set_process(false)
	set_process_unhandled_input(false)
	var jog := jogo.get("jogador") as Jogador
	if jog:
		jog.travado = false
	if _camera_do_jogo:
		_camera_do_jogo.current = true
	Input.mouse_mode = _mouse_antes


func _aplicar() -> void:
	rotation = Vector3(_pitch, _yaw, 0.0)


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= evento.relative.x * 0.003
		_pitch = clampf(_pitch - evento.relative.y * 0.003, -1.5, 1.5)
		_aplicar()


func _process(delta: float) -> void:
	var v := VEL
	if Input.is_physical_key_pressed(KEY_SHIFT):
		v = VEL_RAPIDA
	elif Input.is_physical_key_pressed(KEY_CTRL):
		v = VEL_LENTA
	var d := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		d -= global_transform.basis.z
	if Input.is_physical_key_pressed(KEY_S):
		d += global_transform.basis.z
	if Input.is_physical_key_pressed(KEY_A):
		d -= global_transform.basis.x
	if Input.is_physical_key_pressed(KEY_D):
		d += global_transform.basis.x
	if Input.is_physical_key_pressed(KEY_SPACE):
		d += Vector3.UP
	if Input.is_physical_key_pressed(KEY_C):
		d -= Vector3.UP
	global_position += d.normalized() * v * delta


## Põe o drone em `pos` olhando para `alvo` (para fotos e passeios automáticos).
func olhar(pos: Vector3, alvo: Vector3) -> void:
	global_position = pos
	look_at(alvo)
	_yaw = rotation.y
	_pitch = rotation.x
