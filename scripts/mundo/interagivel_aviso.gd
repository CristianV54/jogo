class_name InteragivelAviso
extends Interagivel
## Interagível que só mostra uma mensagem (porta trancada, placa...). Reutilizável: define `mensagem` e `texto`.

@export var mensagem := ""


func _ready() -> void:
	super()
	uma_vez = false


func _ao_acionar() -> void:
	if GerenciadorMissoes.instancia:
		GerenciadorMissoes.instancia.aviso.emit(mensagem, 3.5)
