class_name PainelDeOficio
extends Control
## Janela de COMÉRCIO e de FORJA (uma lista de botões no meio da tela; clica-se com o mouse, Esc fecha).
##   - loja: comprar o que o mercador tem, vender o que está na bolsa (por metade do preço) e PECHINCHAR uma vez por
##     visita: se der certo, compra-se 20% mais barato e vende-se 20% mais caro; se der errado, o mercador se ofende e
##     os preços pioram 10%.
##   - forja: as receitas de Itens.RECEITAS; cada uma mostra o que pede e só acende quando o Torin tem o material.
## Não guarda nada: lê e mexe na bolsa do jogador e avisa por `fechar_pedido`.

signal fechar_pedido

const COR_FUNDO := Color(0.06, 0.06, 0.08, 0.94)
const COR_OURO := Color(0.95, 0.72, 0.2)

var jogador: Jogador
var modo := "loja"
var oferta: Array = []        # ids que este mercador vende
var _ajuste := 1.0            # 1 = preço normal; 0,8 depois de pechinchar bem; 1,1 depois de pechinchar mal
var _pechinchou := false
var _rng := RandomNumberGenerator.new()
var _titulo: Label
var _moedas: Label
var _aviso: Label
var _lista: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var fundo := ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.position = Vector2(240, 60)
	fundo.size = Vector2(800, 600)
	add_child(fundo)
	_titulo = _rotulo(Vector2(270, 76), 30, COR_OURO)
	_moedas = _rotulo(Vector2(760, 84), 22, Color(0.95, 0.92, 0.82))
	_aviso = _rotulo(Vector2(270, 612), 20, COR_OURO)
	var rolagem := ScrollContainer.new()
	rolagem.position = Vector2(270, 130)
	rolagem.size = Vector2(740, 470)
	add_child(rolagem)
	_lista = VBoxContainer.new()
	_lista.custom_minimum_size = Vector2(720, 0)
	_lista.add_theme_constant_override("separation", 6)
	rolagem.add_child(_lista)


func abrir(novo_modo: String, itens_a_venda: Array, nome: String) -> void:
	modo = novo_modo
	oferta = itens_a_venda
	_ajuste = 1.0
	_pechinchou = false
	_titulo.text = nome
	_aviso.text = "Esc fecha"
	visible = true
	_montar()


func preco_de_compra(item: String) -> int:
	return maxi(1, int(ceil(Itens.preco(item) * _ajuste)))


func preco_de_venda(item: String) -> int:
	return maxi(1, int(floor(Itens.preco(item) * 0.5 * (2.0 - _ajuste))))


func comprar(item: String) -> bool:
	if not jogador.gastar_item("moeda", preco_de_compra(item)):
		_aviso.text = "Faltam moedas para %s." % Itens.nome(item)
		return false
	jogador.coletar(item, 1)
	_aviso.text = "Comprou %s." % Itens.nome(item)
	_montar()
	return true


func vender(item: String) -> bool:
	if item == jogador.equipado["arma"] or item == jogador.equipado["armadura"]:
		if int(jogador.inventario.get(item, 0)) <= 1:
			_aviso.text = "Está equipado: não dá para vender o último."
			return false
	var valor := preco_de_venda(item)
	if not jogador.gastar_item(item, 1):
		return false
	jogador.coletar("moeda", valor)
	_aviso.text = "Vendeu %s por %d moedas." % [Itens.nome(item), valor]
	_montar()
	return true


## Pechincha: uma tentativa por visita. `sorte` de 0 a 1 (o teste passa um valor fixo).
func pechinchar(sorte := -1.0) -> bool:
	if _pechinchou:
		return false
	_pechinchou = true
	var deu := (sorte if sorte >= 0.0 else _rng.randf()) < 0.55
	_ajuste = 0.8 if deu else 1.1
	_aviso.text = "O mercador ri e baixa o preço." if deu else "O mercador fecha a cara: os preços pioraram."
	_montar()
	return deu


func forjar(indice: int) -> bool:
	var r: Dictionary = Itens.RECEITAS[indice]
	for item in r["entra"]:
		if int(jogador.inventario.get(item, 0)) < int(r["entra"][item]):
			_aviso.text = "Falta material para %s." % Itens.nome(r["sai"])
			return false
	for item in r["entra"]:
		jogador.gastar_item(item, int(r["entra"][item]))
	jogador.coletar(r["sai"], int(r["qtd"]))
	_aviso.text = "Forjou %s." % Itens.nome(r["sai"])
	_montar()
	return true


func _montar() -> void:
	for filho in _lista.get_children():
		_lista.remove_child(filho)
		filho.queue_free()
	_moedas.text = "Moedas: %d" % int(jogador.inventario.get("moeda", 0))
	if modo == "forja":
		for i in Itens.RECEITAS.size():
			var r: Dictionary = Itens.RECEITAS[i]
			var pede: Array[String] = []
			var pode := true
			for item in r["entra"]:
				var tem := int(jogador.inventario.get(item, 0))
				pede.append("%d %s (tem %d)" % [int(r["entra"][item]), Itens.nome(item), tem])
				if tem < int(r["entra"][item]):
					pode = false
			_botao("Forjar %s    pede: %s" % [Itens.nome(r["sai"]), ", ".join(pede)], pode, forjar.bind(i))
		return
	_botao("Pechinchar (uma tentativa)", not _pechinchou, func() -> void: pechinchar())
	_secao("COMPRAR")
	for item in oferta:
		_botao("%s    %d moedas" % [Itens.nome(item), preco_de_compra(item)], int(jogador.inventario.get("moeda", 0)) >= preco_de_compra(item), comprar.bind(item))
	_secao("VENDER")
	for item in Itens.ORDEM:
		if item != "moeda" and int(jogador.inventario.get(item, 0)) > 0 and Itens.preco(item) > 0:
			_botao("%s (tem %d)    %d moedas" % [Itens.nome(item), int(jogador.inventario[item]), preco_de_venda(item)], true, vender.bind(item))


func _secao(texto: String) -> void:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", COR_OURO)
	_lista.add_child(l)


func _botao(texto: String, ligado: bool, acao: Callable) -> void:
	var b := Button.new()
	b.text = texto
	b.disabled = not ligado
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(720, 40)
	b.add_theme_font_size_override("font_size", 19)
	b.pressed.connect(acao)
	_lista.add_child(b)


func _rotulo(pos: Vector2, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	add_child(l)
	return l


func _unhandled_key_input(evento: InputEvent) -> void:
	if visible and evento.is_pressed() and (evento as InputEventKey).physical_keycode == KEY_ESCAPE:
		fechar_pedido.emit()
		get_viewport().set_input_as_handled()
