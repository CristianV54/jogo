class_name PilhaDeItem
extends Interagivel
## Pilha de um item no chão (aço imperial no depósito, Ferro Negro bruto no acampamento): E recolhe `qtd` unidades.

var item := "aco_imperial"
var qtd := 1


func _ready() -> void:
	super()
	texto = "Pegar %s" % Itens.nome(item)
	raio = 2.4
	var modelo := load(Itens.DADOS[item]["modelo"]) as PackedScene
	for k in 3:
		var m := modelo.instantiate() as Node3D
		m.scale = Vector3.ONE * 2.2
		m.position = Vector3((k - 1) * 0.5, 0.05 + (0.18 if k == 1 else 0.0), 0.0)
		m.rotation.y = k * 0.7
		add_child(m)


func _ao_acionar() -> void:
	var jog := get_tree().get_first_node_in_group("jogador") as Jogador
	if jog:
		jog.coletar(item, qtd)
	for c in get_children():
		(c as Node3D).visible = false
