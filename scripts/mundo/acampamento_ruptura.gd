extends AreaAberta
## Acampamento da Ruptura (Capítulo III): o bando rachou. Vane acampa a leste do Refúgio com os que o seguem, com a
## ponte quebrada sobre o Rio Cinzento e um vau a norte, que leva a Ferrogris. Ao chegar perto do Vane (C3-M1), a cena
## do confronto roda e o objetivo "confronto_visto" é cumprido. Tem Ferro Negro bruto à mão para a entrega à Brenn.

const SUL := Vector2(0.0, 105.0)
const ACAMP := Vector2(0.0, 55.0)
const RIO_Z := -8.0
const VAU := Vector2(24.0, RIO_Z)

var _vane: Npc
var _visto := false


func _ready() -> void:
	nome_area = "Acampamento da Ruptura"
	tam = 260.0
	_rng.seed = 53
	_ambiente_padrao()
	var planos: Array[Vector3] = [Vector3(ACAMP.x, ACAMP.y, 24.0), Vector3(SUL.x, SUL.y, 16.0), Vector3(VAU.x, VAU.y, 14.0), Vector3(VAU.x, -70.0, 14.0)]
	_montar_terreno(17, 7.0, planos, PackedVector2Array([Vector2(0, 135), Vector2(0, 125), Vector2(0, 55), Vector2(16, 20), Vector2(24, -8), Vector2(24, -70), Vector2(24, -118), Vector2(24, -135)]), Color(0.3, 0.38, 0.2), Color(0.18, 0.28, 0.15), 1.0, [{"pontos": Terreno.curva([Vector2(-156, -6.5), Vector2(-100, -9.5), Vector2(-50, -6.5), Vector2(0, -9.5), Vector2(24, -8), Vector2(60, -6.5), Vector2(100, -9.5), Vector2(156, -7)], 3.0), "largura": 9.0, "margem": 7.0, "fundo": 1.4, "agua": true, "vaus": [VAU]}])
	_floresta(2200, func(x: float, z: float) -> bool:
		return Vector2(x, z).distance_to(ACAMP) < 30.0 or Vector2(x, z).distance_to(SUL) < 18.0 or (absf(z - RIO_Z) < 8.0 and absf(x) < 40.0) or Vector2(x, z).distance_to(Vector2(24, -70)) < 14.0)
	_horizonte(Color(0.34, 0.4, 0.36), 120.0, true, -8.0)
	_rio()
	_acampamento()
	var ex: Array = [[ACAMP, 3.0]]
	for x in range(-120, 121, 8):   # o rio fica sem mato
		ex.append([Vector2(float(x), RIO_Z), 6.0])
	VegetacaoRasteira.decorar_zonas(self, terreno, _rng, [[ACAMP, 30.0, 1.2], [SUL, 20.0, 0.8], [VAU, 18.0, 1.0], [Vector2(24.0, -70.0), 18.0, 0.8]], ex)
	_novo_spawn("Entrada", Vector3(0, altura_em(0, 122), 122), Vector3(0, 0, 90))
	_novo_spawn("Principal", Vector3(0, altura_em(0, 122), 122), Vector3(0, 0, 90))
	_novo_spawn("DaFortaleza", Vector3(24, altura_em(24, -104), -104), Vector3(24, 0, -60))
	_portal(Vector3(0, altura_em(0, 126), 126), "refugio_do_pinhal", "DaFronteira", 16.0)
	_portal(Vector3(24, altura_em(24, -120), -120), "fronteira_ferrogris", "Entrada", 12.0)
	_gente()


func _rio() -> void:
	for x in range(-152, 152, 8):
		if x > 14 and x < 36:   # o vau: água rasa, só o leito de pedra
			continue
		var cs := CollisionShape3D.new()   # rio fundo: parede baixa invisível, só o vau e a ponte passam
		var forma := BoxShape3D.new()
		forma.size = Vector3(8.4, 4.0, 6.0)
		cs.shape = forma
		cs.position = Vector3(x + 4.0, altura_em(x + 4.0, RIO_Z) + 1.0, RIO_Z)
		_solidos.add_child(cs)
	for k in 7:   # pedras do vau
		_rocha(VAU + Vector2(-6.0 + k * 2.0, 1.5 * sin(k)), 0.45, false, 70.0 + k)
	# ponte quebrada: pilares e tábuas só até a metade, o resto caído na água
	var madeira := VilaRefugio._mat(Color(0.3, 0.2, 0.11))
	for dz in [-4.0, 4.0]:
		for x in [-24.0, -16.0]:
			VilaRefugio._caixa(Vector3(x, altura_em(x, RIO_Z + dz) + 1.0, RIO_Z + dz), Vector3(0.4, 2.4, 0.4), madeira, true)
	for k in 5:
		VilaRefugio._caixa(Vector3(-24.0 + k * 1.6, altura_em(-24.0, RIO_Z) + 1.9, RIO_Z), Vector3(1.4, 0.2, 7.0), madeira, true)
	for k in 4:   # tábuas caídas e inclinadas
		var t := VilaRefugio._caixa(Vector3(-15.0 + k * 1.1, altura_em(-15.0, RIO_Z) + 0.3, RIO_Z + (k - 1.5) * 1.2), Vector3(1.2, 0.18, 4.0), madeira, false, 0.4 * k)
		t.rotation.x = 0.3
	_placa_em_poste(Vector2(-20.0, RIO_Z + 11.0), "Ponte quebrada: use o vau")
	_placa_em_poste(Vector2(30.0, RIO_Z + 9.0), "Vau do Rio Cinzento")


func _acampamento() -> void:
	var c := ACAMP
	_fogueira(c, 1.1, 16.0)
	for i in 6:   # tendas em semicírculo, bandeiras do bando rachado
		var a := PI * (0.15 + i * 0.14)
		var p := c + Vector2(cos(a), -sin(a)) * 15.0
		_tenda(p, a + PI / 2.0, [Color(0.42, 0.22, 0.18), Color(0.34, 0.3, 0.2), Color(0.28, 0.26, 0.32)][i % 3])
	_bandeira(c + Vector2(-8.0, -8.0))
	_bandeira(c + Vector2(8.0, -8.0))
	var mesa := c + Vector2(-5.0, 6.0)
	ConstrutorCasa._movel(self, _solidos, "Table_Large", mesa.x, mesa.y, 0.0, _y(mesa))
	ConstrutorCasa._movel(self, _solidos, "Barrel", c.x + 11.0, c.y + 7.0, 0.0, _y(c))
	ConstrutorCasa._movel(self, _solidos, "Chest_Wood", c.x + 12.4, c.y + 7.0, 15.0, _y(c))
	for lado in [-1.0, 1.0]:
		ConstrutorCasa._movel(self, _solidos, "Bench", c.x + lado * 3.4, c.y + 1.2, 90.0 * lado, _y(c))
	# armas empilhadas e pilha de Ferro Negro bruto (para a Brenn forjar o equipamento)
	for k in 3:
		var pilha := PilhaDeItem.new()
		pilha.item = "minerio_bruto"
		pilha.qtd = 1
		pilha.position = Vector3(c.x + 9.0 + k * 2.6, _y(c + Vector2(9.0, -4.0)), c.y - 4.0)
		add_child(pilha)
	_placa_em_poste(Vector2(4.0, 112.0), "Acampamento da Ruptura")
	_placa_em_poste(c + Vector2(13.0, -5.5), "Ferro Negro: serve para a Brenn")


func _gente() -> void:
	var c := ACAMP
	_vane = _npc("Vane", "Líder do bando", "res://scenes/personagens/vane.tscn", c + Vector2(0.0, -6.0),
		PackedStringArray(["Você demorou, Torin.", "Eu só quero poder para proteger o bando. Você ainda vai entender."]),
		[{"esperar": 9.0, "anim": "Idle_Talking", "olhar": c + Vector2(0, 30)}, {"esperar": 5.0, "anim": "Idle", "olhar": Vector2(24, -40)}])
	_npc("Soldado do Vane", "Seguidor", "res://scenes/personagens/soldado_rebelde.tscn", c + Vector2(-4.0, -4.0),
		PackedStringArray(["O Vane é o único que não tem medo do Império.", "Dizem que ele quer domar os dragões. Eu não sei, não."]),
		[{"esperar": 6.0, "anim": "Idle", "olhar": c}, {"fazer": "Interact", "seg": 5.0, "olhar": c + Vector2(-6, 0)}])
	_npc("Rebelde da Guarda", "Vigia do vau", "res://scenes/personagens/soldado_rebelde.tscn", VAU + Vector2(-5.0, 6.0),
		PackedStringArray(["Ferrogris fica ao norte, depois do vau. Quem entra lá não sai com facilidade."]),
		[{"esperar": 8.0, "anim": "Idle", "olhar": Vector2(24, -40)}, {"ir": VAU + Vector2(-9.0, 6.0), "vel": 1.2}, {"esperar": 6.0, "anim": "Idle", "olhar": VAU}, {"ir": VAU + Vector2(-5.0, 6.0), "vel": 1.2}])


## Cena do confronto (C3-M1): ao chegar perto do Vane com a missão ativa, o diálogo roda sozinho uma vez.
func _process(_delta: float) -> void:
	if _visto or _vane == null:
		return
	var m := GerenciadorMissoes.instancia
	if m == null or not m.ativas.has("C3-M1"):
		return
	var js := get_tree().get_nodes_in_group("jogador")
	if js.is_empty() or (js[0] as Node3D).global_position.distance_to(_vane.global_position) > 11.0:
		return
	var jogo := get_tree().get_first_node_in_group("jogo")
	if jogo == null:
		return
	_visto = true
	_vane.pausar()
	_vane.olhar_para((js[0] as Node3D).global_position)
	jogo.cena_dialogo([
		["Vane", "Torin. Você trouxe um dragão até aqui. Isso muda tudo."],
		["Torin", "Fagulha não é arma, Vane. É um amigo."],
		["Vane", "Você viu o que um dragão pode fazer. Com três deles ao nosso lado, Ferrogris cairia em uma noite."],
		["Torin", "Você não quer libertá-los. Quer pôr os dragões sob as suas ordens."],
		["Vane", "Liberdade é uma palavra bonita para quem nunca precisou vencer uma guerra. Eu enterrei vinte dos nossos, Torin. Vinte. Cada um deles confiou em mim."],
		["Torin", "E quando você vencer? Vai soltar as correntes ou pô-las em outras pessoas?"],
		["Vane", "Você prometeu destruir os obeliscos comigo. Eu prometi proteger o bando. Uma das duas promessas tem que quebrar, e não vai ser a minha."],
		["Soldado do Vane", "Desculpe, Torin. O Vane é o único que nunca teve medo do Império. Eu fico com ele."],
		["Vane", "O bando agora é meu. Quem não segue, sai. A Brenn já escolheu o lado dela: foi para o seu."],
		["Vane", "Se quiser seguir a sua causa, passe pelo vau a norte. Ferrogris vai lhe ensinar o que o Império faz com quem pensa como você."],
	], func() -> void:
		_vane.retomar()
		GerenciadorMissoes.evento("interagir", "confronto_visto"))
