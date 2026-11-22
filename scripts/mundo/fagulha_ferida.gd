class_name FagulhaFerida
extends Interagivel
## Ponto de interação ao lado da Fagulha ferida na clareira: alimentá-la com carne conta para o resgate.

func _ready() -> void:
	super()
	id = "fagulha_ferida"
	texto = "Alimentar o dragão ferido"
	uma_vez = false
	raio = 6.0


func disponivel() -> bool:
	return GerenciadorMissoes.instancia != null and not GerenciadorMissoes.instancia.concluidas.has("C1-M4")


func _ao_acionar() -> void:
	GerenciadorMissoes.instancia.tentar_entrega("fagulha")
