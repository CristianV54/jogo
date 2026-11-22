class_name Montaria
extends Node
## Faz de uma criatura (filho direto do dono) algo que o jogador monta. Quem se move é o corpo do jogador;
## a criatura é posta embaixo dele a cada quadro e toca a animação certa. O assento acompanha um osso do esqueleto.

@export var nome := "Montaria"
@export var osso_assento := "Torso"
@export var elevacao := 0.2            # metros acima do osso, para a sela ficar em cima do dorso
@export var voa := false
@export var velocidade_andando := 5.5
@export var velocidade_correndo := 11.0
@export var velocidade_voo := 14.0
@export var velocidade_voo_rapido := 24.0
@export var velocidade_vertical := 8.0
@export var camera_altura := 2.2
@export var camera_distancia := 7.0
@export var persistente := false       # true: sobrevive à troca de área (o Fagulha); false: o jogador desmonta ao trocar

var montada := false
var ativa := true
var dono: Node3D
var _esqueleto: Skeleton3D
var _osso := -1
var _anim: AnimationPlayer


func _ready() -> void:
	add_to_group("montarias")
	dono = get_parent() as Node3D
	_esqueleto = dono.find_child("Skeleton3D", true, false)
	_anim = dono.find_child("AnimationPlayer", true, false)
	if _esqueleto:
		_osso = _esqueleto.find_bone(osso_assento)


func assento_global() -> Vector3:
	if _esqueleto and _osso >= 0:
		return _esqueleto.global_transform * _esqueleto.get_bone_global_pose(_osso).origin + Vector3(0.0, elevacao, 0.0)
	return dono.global_position + Vector3(0.0, 1.0 + elevacao, 0.0)


## Põe a criatura embaixo do corpo do jogador. O modelo olha para +Z; o corpo do jogador, para -Z.
func posicionar(pos: Vector3, giro_do_corpo: float) -> void:
	dono.global_position = pos
	dono.rotation.y = giro_do_corpo + PI


func tocar(animacao: String) -> void:
	if _anim and _anim.has_animation(animacao) and _anim.current_animation != animacao:
		_anim.play(animacao, 0.25)
