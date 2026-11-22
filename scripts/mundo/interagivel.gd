class_name Interagivel
extends Node3D
## Objeto do mundo que o jogador aciona com E quando está perto (tocha, quadro, cesto, jaula...). As subclasses
## montam o visual e implementam `_ao_acionar`. Cada acionamento avisa o sistema de missões com um evento "interagir".

signal acionado

@export var id := ""
@export var texto := "Usar"
@export var raio := 2.2
@export var uma_vez := true

var usado := false


func _ready() -> void:
	add_to_group("interagiveis")


func disponivel() -> bool:
	return not (usado and uma_vez)


func acionar() -> void:
	if not disponivel():
		return
	usado = true
	_ao_acionar()
	acionado.emit()
	if id != "":
		GerenciadorMissoes.evento("interagir", id)


func _ao_acionar() -> void:
	pass
