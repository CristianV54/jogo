class_name Portal
extends Area3D
## Faixa invisível no chão: quando o jogador entra, pede a troca para outra área.

signal usado(destino: String, spawn: String)

@export var destino := ""
@export var spawn := "Principal"
@export var tamanho := Vector3(6.0, 4.0, 2.0)

var _usado := false


func _ready() -> void:
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = tamanho
	cs.shape = caixa
	cs.position.y = tamanho.y / 2.0
	add_child(cs)
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_ao_entrar)


func _ao_entrar(corpo: Node3D) -> void:
	if Mundo.ativo:
		return   # no mundo contínuo não há portais: as regiões se ligam por estradas
	if corpo is Jogador and not _usado:
		_usado = true   # uma vez só por vez que a área é carregada
		usado.emit(destino, spawn)
