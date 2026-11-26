class_name DomarDragao
extends Interagivel
## O gesto de domar: com E, perto do dragão pousado no ninho. Custa 3 carnes; sem elas o dragão rosna e nada acontece.

const CARNES := 3

var dragao: DragaoSelvagem


func _ready() -> void:
	super._ready()
	texto = "Oferecer %d carnes ao dragão" % CARNES
	raio = 5.0
	uma_vez = false


func disponivel() -> bool:
	return dragao != null and not dragao.domado


func _ao_acionar() -> void:
	var jogador := get_tree().get_first_node_in_group("jogador")
	if jogador and jogador.gastar_item("carne", CARNES):
		dragao.domar()
		return
	var jogo := get_tree().get_first_node_in_group("jogo")
	if jogo:
		jogo.hud.mensagem("O dragão rosna e não deixa você chegar. Traga %d carnes (de caça ou do mercado)." % CARNES, 4.0)
