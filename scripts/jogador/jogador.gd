class_name Jogador
extends CharacterBody3D
## Corpo do jogador (Torin): anda e corre em relação à câmera (WASD, Shift), pula (Espaço), golpeia (J ou clique),
## rola (K) e leva dano.
## O visual é o Torin real; o modelo olha para +Z, então o nó Visual fica girado 180° para olhar para a frente (-Z).
## A entrada pode ser forçada por código, só para os testes automáticos.

signal vida_mudou(atual: int, maximo: int)
signal morreu

@export var camera: CameraTerceiraPessoa
@export var velocidade_andando := 4.0
@export var velocidade_correndo := 7.0
@export var gravidade := 20.0
@export var giro := 10.0
@export var vida_max := 100
@export var dano_golpe := 22
@export var alcance_golpe := 2.4
@export var momento_do_golpe := 0.5     # segundos depois do início de Sword_Attack em que a lâmina acerta
@export var duracao_golpe := 1.0
@export var forca_pulo := 7.5               # com gravidade 20: sobe ~1,4 m
@export var velocidade_rolamento := 9.0
@export var duracao_rolamento := 0.65
@export var regeneracao_apos := 4.0        # segundos sem levar dano para começar a recuperar vida

var entrada_forcada := Vector2.ZERO   # x: direita(+), y: trás(+). Zero = usa o teclado.
var correndo_forcado := false
var animacao_atual := ""
var vida := 100
var travado := false                   # diálogo aberto ou cena especial: não anda nem golpeia
var morto := false
var _golpeando := false
var _rolando := false
var _dir_rolamento := Vector3.ZERO
var _sem_dano := 0.0
var _pulo_pedido := false
var _tempo_no_ar := 0.0
var _pouso := 0.0
var _estava_no_chao := true
var _regen := 0.0
var _invulneravel := 0.0
var _reacao := 0.0

@onready var visual: Humanoide = $Visual


func _ready() -> void:
	vida = vida_max
	add_to_group("jogador")


func _physics_process(delta: float) -> void:
	_invulneravel = maxf(0.0, _invulneravel - delta)
	_reacao = maxf(0.0, _reacao - delta)
	_pouso = maxf(0.0, _pouso - delta)
	_regenerar(delta)
	var entrada := Vector2.ZERO
	var correndo := false
	if not travado and not morto and not _golpeando and _reacao <= 0.0:
		entrada = _ler_entrada()
		correndo = correndo_forcado or Input.is_physical_key_pressed(KEY_SHIFT)
	var yaw := camera.yaw if camera else 0.0
	var direcao := Vector3(entrada.x, 0.0, entrada.y).rotated(Vector3.UP, yaw)
	var velocidade := velocidade_correndo if correndo else velocidade_andando

	velocity.x = direcao.x * velocidade
	velocity.z = direcao.z * velocidade
	if _rolando:
		velocity.x = _dir_rolamento.x * velocidade_rolamento
		velocity.z = _dir_rolamento.z * velocidade_rolamento
	if _pulo_pedido and is_on_floor() and not travado and not morto and not _golpeando and not _rolando:
		velocity.y = forca_pulo   # pulo para CIMA; o movimento horizontal continua o que o jogador está fazendo
		_tempo_no_ar = 0.0
	elif is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravidade * delta
	_pulo_pedido = false
	move_and_slide()
	if is_on_floor():
		if not _estava_no_chao:
			_pouso = 0.3
		_tempo_no_ar = 0.0
	else:
		_tempo_no_ar += delta
	_estava_no_chao = is_on_floor()

	if direcao.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direcao.x, -direcao.z), giro * delta)
	if not _golpeando and not _rolando and not morto and _reacao <= 0.0:
		_animar(direcao.length(), correndo)


func _unhandled_input(evento: InputEvent) -> void:
	if travado or morto:
		return
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode == KEY_J:
		golpear()
	elif evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode == KEY_SPACE:
		pular()
	elif evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode == KEY_K:
		rolar()
	elif evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		golpear()


func _animar(movimento: float, correndo: bool) -> void:
	var nome := "Idle"
	if not is_on_floor():
		nome = "Jump_Start" if _tempo_no_ar < 0.25 and velocity.y > 0.0 else "Jump"
	elif _pouso > 0.0 and movimento < 0.01:
		nome = "Jump_Land"
	elif movimento > 0.01:
		nome = "Sprint" if correndo else "Jog_Fwd"
	if nome != animacao_atual:
		visual.tocar(nome)
		animacao_atual = nome


## Pulo: sobe na vertical e segue com o movimento horizontal atual.
func pular() -> void:
	_pulo_pedido = true


## Golpe de espada: toca Sword_Attack e, no momento do impacto, fere os inimigos à frente.
func golpear() -> void:
	if _golpeando or morto or travado:
		return
	_golpeando = true
	animacao_atual = "Sword_Attack"
	visual.tocar("Sword_Attack", 0.05)
	await get_tree().create_timer(momento_do_golpe).timeout
	if not morto:
		_acertar()
	await get_tree().create_timer(maxf(0.0, duracao_golpe - momento_do_golpe)).timeout
	_golpeando = false
	animacao_atual = ""


## Rolamento: desliza por 0,65 s na direção do movimento (ou para onde olha) e fica invulnerável nesse tempo.
func rolar() -> void:
	if _rolando or _golpeando or morto or travado:
		return
	var entrada := _ler_entrada()
	var yaw := camera.yaw if camera else 0.0
	var dir := Vector3(entrada.x, 0.0, entrada.y).rotated(Vector3.UP, yaw)
	if dir.length() < 0.1:
		dir = -global_transform.basis.z
	_dir_rolamento = Vector3(dir.x, 0.0, dir.z).normalized()
	rotation.y = atan2(-_dir_rolamento.x, -_dir_rolamento.z)
	_rolando = true
	_invulneravel = maxf(_invulneravel, duracao_rolamento)
	animacao_atual = "Roll"
	visual.tocar("Roll", 0.05)
	await get_tree().create_timer(duracao_rolamento).timeout
	_rolando = false
	animacao_atual = ""


func _regenerar(delta: float) -> void:
	_sem_dano += delta
	if morto or vida >= vida_max or _sem_dano < regeneracao_apos:
		return
	_regen += delta
	if _regen >= 0.5:
		_regen = 0.0
		vida = mini(vida_max, vida + 1)
		vida_mudou.emit(vida, vida_max)


func _acertar() -> void:
	var frente := -global_transform.basis.z
	for no in get_tree().get_nodes_in_group("inimigos"):
		var ini: Inimigo = no as Inimigo
		if ini == null or ini.estado == Inimigo.Estado.MORTO:
			continue
		var d := ini.global_position - global_position
		d.y = 0.0
		var raio := alcance_golpe + ini.raio_colisao
		if d.length() <= raio and (d.length() < 0.5 or frente.dot(d.normalized()) > 0.1):
			ini.receber_dano(dano_golpe, self)


func receber_dano(quantidade: int, _de: Node3D = null) -> void:
	if morto or _invulneravel > 0.0:
		return
	vida = maxi(0, vida - quantidade)
	_sem_dano = 0.0
	_invulneravel = 0.7
	vida_mudou.emit(vida, vida_max)
	if vida <= 0:
		morto = true
		animacao_atual = "Death01"
		visual.tocar("Death01", 0.05)
		morreu.emit()
	else:
		_reacao = 0.45
		animacao_atual = "Hit_Chest"
		visual.tocar("Hit_Chest", 0.05)


func reviver() -> void:
	vida = vida_max
	morto = false
	_golpeando = false
	_rolando = false
	_invulneravel = 1.5
	animacao_atual = ""
	vida_mudou.emit(vida, vida_max)


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
