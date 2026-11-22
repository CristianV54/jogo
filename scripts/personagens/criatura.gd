class_name Criatura
extends Node3D
## Criatura com animações no próprio modelo (dragões e animais). O nó filho "Modelo" é o .glb importado.
## Mesma interface do Humanoide (tocar, tem), para o Inimigo tratar os dois do mesmo jeito.

@export var animacao_inicial := "Idle"

@onready var modelo: Node3D = $Modelo
var animacoes: AnimationPlayer


func _ready() -> void:
	animacoes = modelo.find_child("AnimationPlayer", true, false)
	if animacoes:
		tocar(animacao_inicial)


func tocar(nome: String, mistura := 0.2) -> void:
	if animacoes and animacoes.has_animation(nome) and animacoes.current_animation != nome:
		animacoes.play(nome, mistura)


func tem(nome: String) -> bool:
	return animacoes != null and animacoes.has_animation(nome)
