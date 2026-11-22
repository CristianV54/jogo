class_name AnimalVila
extends Node3D
## Animal de vila/fazenda: fica parado um tempo, anda até um ponto perto de casa, para de novo.
## Leva golpes: foge e, se a vida zera, tomba. Se `montavel`, o jogador pode montá-lo (ver Montaria).
## O modelo olha para +Z (como o Fagulha). Sem colisão: não bloqueia o jogador.

@export var modelo: PackedScene
@export var nome := "Animal"
@export var raio_vagar := 4.0
@export var velocidade := 1.0
@export var anim_parado := "Idle"
@export var anim_andar := "WalkSlow"
@export var giro := 4.0
@export var vida_max := 20
@export var raio_colisao := 0.6       # alcance do golpe do jogador contra este animal
@export var montavel := false

var altura_em: Callable   # (x, z) -> altura do chão; se vazio, o animal fica em y = 0
var vida := 0
var morto := false
var montaria: Montaria

var _casa := Vector3.ZERO
var _destino := Vector3.ZERO
var _espera := 0.0
var _andando := false
var _fuga := 0.0
var _dir_fuga := Vector3.ZERO
var _anim: AnimationPlayer
var _visual: Node3D


func _ready() -> void:
	_visual = modelo.instantiate()
	add_child(_visual)
	_anim = _visual.find_child("AnimationPlayer", true, false)
	_casa = position
	_espera = randf_range(0.5, 4.0)
	vida = vida_max
	add_to_group("atingiveis")
	if montavel:
		montaria = Montaria.new()
		montaria.nome = nome
		montaria.osso_assento = "Torso"
		montaria.elevacao = 0.2
		montaria.velocidade_andando = 6.0
		montaria.velocidade_correndo = 13.0
		montaria.camera_altura = 2.3
		montaria.camera_distancia = 6.5
		add_child(montaria)
	_tocar(anim_parado)


func _physics_process(delta: float) -> void:
	if morto or (montaria and montaria.montada):
		return
	if _fuga > 0.0:
		_fuga -= delta
		position += _dir_fuga * velocidade * 4.0 * delta
		rotation.y = lerp_angle(rotation.y, atan2(_dir_fuga.x, _dir_fuga.z), giro * 2.0 * delta)
		_tocar("Run" if _tem("Run") else anim_andar)
		if _fuga <= 0.0:
			_casa = position   # volta a vagar a partir de onde parou
			_andando = false
			_espera = randf_range(1.0, 3.0)
			_tocar(anim_parado)
	elif _andando:
		var ate := _destino - position
		ate.y = 0.0
		if ate.length() < 0.25:
			_andando = false
			_espera = randf_range(3.0, 9.0)
			_tocar(anim_parado)
		else:
			var direcao := ate.normalized()
			position += direcao * velocidade * delta
			rotation.y = lerp_angle(rotation.y, atan2(direcao.x, direcao.z), giro * delta)
	else:
		_espera -= delta
		if _espera <= 0.0:
			var ang := randf() * TAU
			_destino = _casa + Vector3(cos(ang), 0.0, sin(ang)) * randf_range(0.4, 1.0) * raio_vagar
			_andando = true
			_tocar(anim_andar)
	if altura_em.is_valid():
		position.y = altura_em.call(position.x, position.z)


func receber_dano(quantidade: int, de: Node3D = null) -> void:
	if morto:
		return
	vida = maxi(0, vida - quantidade)
	Efeitos.piscar(_visual)
	if vida <= 0:
		morto = true
		if montaria:
			montaria.ativa = false
		if _tem("Death"):
			_anim.play("Death", 0.1)
		await get_tree().create_timer(12.0).timeout
		queue_free()
		return
	var longe := global_position - (de.global_position if de else global_position - Vector3.FORWARD)
	longe.y = 0.0
	_dir_fuga = longe.normalized() if longe.length() > 0.01 else Vector3.FORWARD
	_fuga = 3.0


func _tem(nome_anim: String) -> bool:
	return _anim != null and _anim.has_animation(nome_anim)


func _tocar(nome_anim: String) -> void:
	if _anim and _anim.has_animation(nome_anim) and _anim.current_animation != nome_anim:
		_anim.play(nome_anim, 0.3)
