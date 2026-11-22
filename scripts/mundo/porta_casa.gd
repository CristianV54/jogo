class_name PortaCasa
extends Node3D
## Porta de casa: abre sozinha quando o jogador chega perto e fecha quando ele se afasta. A folha gira na dobradiça
## (este nó fica na dobradiça). Fechada, a porta bloqueia a passagem (`corpo`); aberta, deixa livre.

@export var giro_base := 0.0            # giro da fachada, em graus
@export var abertura := 100.0           # quanto a folha gira para abrir, em graus
@export var raio_abrir := 2.8
@export var raio_fechar := 3.8
@export var velocidade := 220.0         # graus por segundo

var folha: Node3D
var corpo: StaticBody3D                 # colisão do vão, ativa só com a porta quase fechada
var aberta := false
var angulo := 0.0


func _process(delta: float) -> void:
	var jog := get_tree().get_first_node_in_group("jogador") as Node3D
	if jog:
		var d := jog.global_position - global_position
		d.y = 0.0
		if not aberta and d.length() < raio_abrir:
			aberta = true
		elif aberta and d.length() > raio_fechar:
			aberta = false
	angulo = move_toward(angulo, abertura if aberta else 0.0, velocidade * delta)
	if folha:
		folha.rotation_degrees.y = giro_base + angulo
	if corpo:
		corpo.collision_layer = 1 if angulo < abertura * 0.3 else 0
