class_name Fagulha
extends Node3D
## Fagulha acompanha o alvo: parado perto, andando a distância média, correndo quando longe.
## Tecla F alterna o voo (sobe e paira em cima do alvo). O modelo olha para +Z (medido com a cabeça e a pélvis).

@export var alvo: Node3D
@export var distancia_parar := 8.0
@export var distancia_correr := 18.0
@export var velocidade_andando := 5.0
@export var velocidade_correndo := 10.0
@export var velocidade_voo := 9.0
@export var altura_voo := 8.0
@export var velocidade_subida := 5.0
@export var giro := 6.0

var modo_voo := false
var montaria: Montaria
var corpo: AnimatableBody3D            # tronco sólido (as asas não bloqueiam); some enquanto está montada
var animacao_atual := ""

@onready var _modelo: Node3D = $Modelo
var _anim: AnimationPlayer


func _ready() -> void:
	_anim = _modelo.find_child("AnimationPlayer", true, false)
	montaria = Montaria.new()
	montaria.nome = "Fagulha"
	montaria.osso_assento = "paunch"
	montaria.elevacao = 0.3
	montaria.voa = true
	montaria.persistente = true
	montaria.velocidade_andando = 6.0
	montaria.velocidade_correndo = 12.0
	montaria.velocidade_voo = 16.0
	montaria.velocidade_voo_rapido = 28.0
	montaria.camera_altura = 3.5
	montaria.camera_distancia = 12.0
	add_child(montaria)
	corpo = Solidos.corpo_movel(self, AABB(Vector3(-0.8, 0.0, -2.8), Vector3(1.6, 1.9, 4.6)))
	_tocar("Idle")


func _unhandled_key_input(evento: InputEvent) -> void:
	if montaria.montada:
		return
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode == KEY_F:
		modo_voo = not modo_voo


func _physics_process(delta: float) -> void:
	corpo.collision_layer = 0 if montaria.montada else Solidos.CAMADA_SERES
	if montaria.montada or alvo == null:
		return
	var ate := alvo.global_position - global_position
	var plano := Vector3(ate.x, 0.0, ate.z)
	var distancia := plano.length()

	var nome := "Idle"
	var velocidade := 0.0
	if modo_voo:
		nome = "Fly"
		velocidade = velocidade_voo if distancia > distancia_parar else 0.0
	elif distancia > distancia_correr:
		nome = "Run"
		velocidade = velocidade_correndo
	elif distancia > distancia_parar:
		nome = "Walk"
		velocidade = velocidade_andando

	if velocidade > 0.0:
		var direcao := plano.normalized()
		global_position += direcao * minf(velocidade * delta, distancia)
		rotation.y = lerp_angle(rotation.y, atan2(direcao.x, direcao.z), giro * delta)

	var altura := altura_voo if modo_voo else 0.0
	global_position.y = move_toward(global_position.y, altura, velocidade_subida * delta)
	_tocar(nome)


func _tocar(nome: String) -> void:
	if nome != animacao_atual and _anim:
		_anim.play(nome, 0.3)
		animacao_atual = nome
