class_name Gatilho
extends Interagivel
## Interagível genérico: ao apertar E chama `ao_usar(este_gatilho)`. Se `uma_vez` for falso, pode ser usado de novo
## (o código que o criou pode zerar `usado`). Quem cria desenha o visual como filho.

var ao_usar: Callable


func _ao_acionar() -> void:
	if ao_usar.is_valid():
		ao_usar.call(self)
