class_name AnimalVila
extends Node3D
## Animal de vila/fazenda: fica parado um tempo, anda até um ponto perto de casa, para de novo.
## O modelo olha para +Z (como o Fagulha). Sem colisão: não bloqueia o jogador.

@export var modelo: PackedScene
@export var raio_vagar := 4.0
@export var velocidade := 1.0
@export var anim_parado := "Idle"
@export var anim_andar := "WalkSlow"
@export var giro := 4.0

var altura_em: Callable   # (x, z) -> altura do chão; se vazio, o animal fica em y = 0

var _casa := Vector3.ZERO
var _destino := Vector3.ZERO
var _espera := 0.0
var _andando := false
var _anim: AnimationPlayer


func _ready() -> void:
	var visual: Node3D = modelo.instantiate()
	add_child(visual)
	_anim = visual.find_child("AnimationPlayer", true, false)
	_casa = position
	_espera = randf_range(0.5, 4.0)
	_tocar(anim_parado)


func _physics_process(delta: float) -> void:
	if _andando:
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


func _tocar(nome: String) -> void:
	if _anim and _anim.has_animation(nome) and _anim.current_animation != nome:
		_anim.play(nome, 0.3)
