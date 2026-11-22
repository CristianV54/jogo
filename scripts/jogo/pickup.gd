class_name Pickup
extends Node3D
## Item largado no chão (carne, couro, lã, presa): gira e flutua, e o jogador o recolhe ao chegar perto.

const MODELOS := {
	"carne": "res://assets/models/itens/carne/carne.glb",
	"couro": "res://assets/models/itens/couro/couro.glb",
	"la": "res://assets/models/itens/la/la.glb",
	"presa": "res://assets/models/itens/presa/presa.glb",
}
const NOMES := {"carne": "Carne", "couro": "Couro", "la": "Lã", "presa": "Presa"}
const RAIO_COLETA := 1.8

@export var item := "carne"
@export var quantidade := 1

var _visual: Node3D
var _t := 0.0


## Largar itens de uma tabela {item: [mínimo, máximo]} ao redor de `pos`, como filhos de `pai`.
static func largar(pai: Node3D, pos: Vector3, tabela: Dictionary) -> void:
	for nome in tabela:
		var faixa: Array = tabela[nome]
		var qtd := randi_range(int(faixa[0]), int(faixa[1]))
		if qtd <= 0:
			continue
		var p := Pickup.new()
		p.item = nome
		p.quantidade = qtd
		pai.add_child(p)
		var desvio := Vector3(randf_range(-0.7, 0.7), 0.0, randf_range(-0.7, 0.7))
		p.global_position = pos + desvio


func _ready() -> void:
	_visual = (load(MODELOS[item]) as PackedScene).instantiate()
	_visual.scale = Vector3.ONE * 1.8
	add_child(_visual)
	_t = randf() * TAU
	add_to_group("pickups")
	var luz := OmniLight3D.new()   # brilho fraco para o item aparecer no mato
	luz.light_color = Color(1.0, 0.9, 0.6)
	luz.light_energy = 0.5
	luz.omni_range = 2.0
	luz.position = Vector3(0.0, 0.5, 0.0)
	add_child(luz)


func _physics_process(delta: float) -> void:
	_t += delta
	_visual.position.y = 0.4 + sin(_t * 2.5) * 0.08
	_visual.rotation.y += delta * 1.6
	var jog := get_tree().get_first_node_in_group("jogador") as Jogador
	if jog and not jog.morto and global_position.distance_to(jog.global_position) < RAIO_COLETA:
		jog.coletar(item, quantidade)
		queue_free()
