class_name Corvo
extends Node3D
## Corvo pousado num poste ou galho. Quando o jogador chega perto, grasna ("Crá!"), ALERTA os inimigos num raio de 45 m
## (eles passam a enxergar o jogador de muito longe) e voa para longe. Usa o modelo da galinha pintado de preto.

const ALCANCE_ALERTA := 45.0

@export var raio_susto := 13.0

var alertou := false
var _visual: Node3D


func _ready() -> void:
	_visual = (load("res://assets/models/criaturas/galinha/galinha.glb") as PackedScene).instantiate()
	_visual.scale = Vector3.ONE * 1.1
	add_child(_visual)
	VariacaoDeCores.aplicar(_visual, "corvo")
	add_to_group("corvos")


func _physics_process(_delta: float) -> void:
	if alertou:
		return
	var j := get_tree().get_first_node_in_group("jogador") as Node3D
	if j and j.global_position.distance_to(global_position) < raio_susto:
		_alertar(j)


func _alertar(jogador: Node3D) -> void:
	alertou = true
	var grito := Label3D.new()
	grito.text = "Crá! Crá!"
	grito.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	grito.position = Vector3(0.0, 0.8, 0.0)
	grito.font_size = 40
	grito.pixel_size = 0.006
	grito.outline_size = 10
	grito.no_depth_test = true
	add_child(grito)
	for no in get_tree().get_nodes_in_group("inimigos"):
		var ini := no as Inimigo
		if ini and not ini.chefe and ini.global_position.distance_to(global_position) < ALCANCE_ALERTA:
			ini.alcance_visao = 90.0   # ouviu o aviso: caça o jogador onde ele estiver
	var rumo := (global_position - jogador.global_position)
	rumo.y = 0.0
	rumo = rumo.normalized()
	var tw := create_tween()
	tw.tween_property(_visual, "rotation:x", -0.3, 0.2)
	tw.tween_property(self, "position", position + rumo * 40.0 + Vector3(0.0, 18.0, 0.0), 3.5).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
