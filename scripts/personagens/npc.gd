class_name Npc
extends Node3D
## Personagem não jogável: um humanoide parado numa animação, que pode olhar para um ponto e tem falas.
## Como no jogador, o modelo olha para +Z; por isso o visual fica girado 180° e o nó olha para -Z.

@export var nome := ""
@export var papel := ""
@export var falas: PackedStringArray = []
@export var animacao := "Idle"
@export var cena: PackedScene

var visual: Humanoide


func _ready() -> void:
	visual = cena.instantiate()
	visual.animacao_inicial = animacao
	visual.rotation_degrees.y = 180.0
	add_child(visual)
	name = nome if nome != "" else name


func olhar_para(alvo: Vector3) -> void:
	var d := alvo - global_position
	rotation.y = atan2(-d.x, -d.z)
