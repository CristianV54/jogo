class_name PasDoMoinho
extends Node3D
## As pás de um moinho de vento: giram devagar em volta do eixo (Z local).

@export var voltas_por_minuto := 5.0


func _process(delta: float) -> void:
	rotate_object_local(Vector3.FORWARD, TAU * voltas_por_minuto / 60.0 * delta)
