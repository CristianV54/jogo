class_name ZonaDeEvento
extends Node3D
## Zona invisível: quando alguém do grupo `grupo_alvo` (o jogador, ou um cavalo...) ENTRA no raio, avisa o sistema de
## missões com o evento ("visitar", id). Dispara de novo cada vez que a pessoa sai e volta.

@export var id := ""
@export var raio := 8.0
@export var grupo_alvo := "jogador"

var _dentro := false
var _t := 0.0


func _physics_process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = 0.3
	var achou := false
	for no in get_tree().get_nodes_in_group(grupo_alvo):
		var d := (no as Node3D).global_position - global_position
		if Vector2(d.x, d.z).length() < raio:
			achou = true
			break
	if achou and not _dentro:
		GerenciadorMissoes.evento("visitar", id)
	_dentro = achou
