class_name Jogo
extends Node3D
## Cena principal: mantém o jogador, o Fagulha, a câmera e a interface, e troca a área do mundo.
## Progresso: cada chefe derrotado liberta o caminho para o próximo. Dá para jogar do início ao fim sem sair daqui.

const AREAS := {
	"refugio_do_pinhal": "res://scenes/areas/refugio_do_pinhal.tscn",
	"pomar_alto": "res://scenes/areas/pomar_alto.tscn",
	"acampamento_ruptura": "res://scenes/areas/acampamento_ruptura.tscn",
	"bosque_velado": "res://scenes/areas/bosque_velado.tscn",
	"fronteira_ferrogris": "res://scenes/areas/fronteira_ferrogris.tscn",
	"cratera_ignis": "res://scenes/areas/cratera_ignis.tscn",
	"valdoria": "res://scenes/areas/valdoria.tscn",
	"castelo_imperial": "res://scenes/areas/castelo_imperial.tscn",
}
## Quem guarda cada passagem: para entrar na área, é preciso ter derrotado o chefe indicado.
const REQUISITOS := {
	"acampamento_ruptura": "gorath",
	"cratera_ignis": "kaelor",
	"valdoria": "ignis_maw",
}
## Missão que precisa estar concluída para o Halk abrir a passagem.
const REQUISITOS_MISSAO := {"bosque_velado": "C1-M4", "fronteira_ferrogris": "C3-M1", "valdoria": "C4-M4", "castelo_imperial": "C5-M1"}
const MENSAGEM_REQUISITO := {
	"bosque_velado": "Halk barra o portão: termine os serviços do Refúgio primeiro (Resgate nas Sombras do Pinhal).",
	"castelo_imperial": "A escadaria do castelo está guardada pela elite imperial: cumpra Portões e Ruas de Valdoria (mercado, suprimentos, guarda de elite).",
	"valdoria": "A estrada para Valdoria só abre com a lâmina final: leve o minério vulcânico e a escama à Brenn (A Lâmina Forjada no Fogo).",
	"fronteira_ferrogris": "A ponte está quebrada e o vau é vigiado. Resolva o que ficou pendente com o Vane e a Brenn (A Quebra do Juramento).",
}
const NOMES_DOS_CHEFES := {"gorath": "Brutamontes Gorath", "kaelor": "General Kaelor", "ignis_maw": "Ignis-Maw", "vane": "Vane", "solon": "Imperador Solon"}

signal area_carregada(nome: String)
signal chefe_derrotado(id: String)
signal fim_de_jogo

var area: AreaBase
var area_nome := ""
var derrotados: Dictionary = {}
var missoes: GerenciadorMissoes
var fagulha_livre := false      # só acompanha o Torin depois do resgate (C1-M4)
var _falas_atuais := PackedStringArray()
var _cena: Array = []
var _cena_i := 0
var _cena_fim: Callable
var _dialogo_npc: Npc
var _dialogo_indice := 0
var _trocando := false
var clima: Clima
var mundo: Mundo
var _lugar := ""
var _t_lugar := 0.0

@onready var jogador: Jogador = $Jogador
@onready var fagulha: Fagulha = $Fagulha
@onready var camera: CameraTerceiraPessoa = $Camera
@onready var hud: Hud = $Interface
@onready var container: Node3D = $AreaAtual


func _ready() -> void:
	add_to_group("jogo")
	Clima.registrar_globais()
	clima = Clima.new()
	clima.name = "Clima"
	add_child(clima)
	clima.camera = camera
	jogador.camera = camera
	jogador.vida_mudou.connect(hud.definir_vida)
	jogador.morreu.connect(_ao_morrer)
	jogador.item_coletado.connect(hud.item_coletado)
	jogador.inventario_mudou.connect(hud.inventario_mudou)
	hud.usar_item.connect(_ao_usar_item)
	hud.fechar_inventario_pedido.connect(_alternar_inventario)
	hud.definir_vida(jogador.vida, jogador.vida_max)
	missoes = GerenciadorMissoes.new()
	missoes.jogador = jogador
	add_child(missoes)
	missoes.aviso.connect(hud.mensagem)
	missoes.missao_iniciada.connect(func(_id: String) -> void: hud.definir_rastreador(missoes.rastreador()))
	missoes.objetivo_atualizado.connect(func(_id: String) -> void: hud.definir_rastreador(missoes.rastreador()))
	missoes.missao_concluida.connect(func(id: String) -> void:
		hud.definir_rastreador(missoes.rastreador())
		if id == "C1-M4":
			liberar_fagulha()
		elif id == "C3-M1":
			_reforcar_equipamento()
		elif id == "C4-M4":
			_forjar_lamina_final())
	fagulha.alvo = null   # a Fagulha começa ferida na clareira do pinhal
	fagulha.montaria.ativa = false
	_trocando = true   # o mundo está sendo construído
	jogador.set_physics_process(false)
	_iniciar_mundo.call_deferred()


## Constrói o mundo contínuo (todas as regiões, estradas, rios, florestas) e põe o Torin no Refúgio.
func _iniciar_mundo() -> void:
	mundo = Mundo.new()
	mundo.name = "Mundo"
	mundo.condicoes = _condicoes_das_barreiras()
	mundo.progresso.connect(func(texto: String) -> void: hud.mensagem(texto, 0.0))
	container.add_child(mundo)
	await mundo.construir()
	hud.mensagem("", 0.01)
	for id in mundo.regioes:
		var a: AreaBase = mundo.regioes[id]
		if a.has_signal("chefe_vida"):
			a.chefe_vida.connect(_ao_vida_do_chefe)
		if a.has_signal("chefe_morreu"):
			a.chefe_morreu.connect(_ao_derrotar_chefe)
	jogador.set_physics_process(true)
	_trocando = false
	var refugio: AreaBase = mundo.regioes["refugio_do_pinhal"]
	fagulha.visible = true
	fagulha.set_physics_process(false)
	fagulha.corpo.collision_layer = Solidos.CAMADA_SERES
	fagulha.global_position = refugio.to_global(refugio.pos_fagulha_ferida())
	ir_para("refugio_do_pinhal", "Principal")
	missoes.iniciar("C1-M1")


## O que abre cada barreira de história do mundo.
func _condicoes_das_barreiras() -> Dictionary:
	return {
		"bosque": func() -> bool: return missoes.concluidas.has("C1-M4"),
		"ruptura": func() -> bool: return derrotados.has("gorath"),
		"ferrogris": func() -> bool: return missoes.concluidas.has("C3-M1"),
		"valdoria": func() -> bool: return missoes.concluidas.has("C4-M4"),
		"castelo": func() -> bool: return missoes.concluidas.has("C5-M1"),
	}


func ir_para(destino: String, spawn: String) -> void:
	if _trocando:
		return
	if REQUISITOS.has(destino) and not derrotados.has(REQUISITOS[destino]):
		hud.mensagem("Caminho bloqueado: derrote %s antes." % NOMES_DOS_CHEFES[REQUISITOS[destino]], 2.5)
		_empurrar_para_tras()
		return
	if REQUISITOS_MISSAO.has(destino) and not missoes.concluidas.has(REQUISITOS_MISSAO[destino]):
		hud.mensagem(MENSAGEM_REQUISITO.get(destino, "Caminho bloqueado."), 3.5)
		_empurrar_para_tras()
		return
	_trocando = true
	if jogador.montaria and not jogador.montaria.persistente:
		jogador.desmontar()   # a montaria some quando se teleporta (morte, atalho)
	hud.esconder_chefe()
	area = mundo.regioes[destino]
	area_nome = destino
	var t := mundo.spawn_global(destino, spawn)
	jogador.global_position = t.origin   # perto do destino para as regiões vizinhas ligarem agora
	mundo.atualizar_atividade()
	var pos := t.origin
	pos.y = area.altura_em(pos.x - area.position.x, pos.z - area.position.z) + area.position.y + 0.3
	jogador.global_position = pos
	jogador.rotation.y = t.basis.get_euler().y
	jogador.velocity = Vector3.ZERO
	camera.yaw = jogador.rotation.y
	if fagulha_livre and not fagulha.montaria.montada:
		fagulha.modo_voo = false
		fagulha.global_position = pos + Vector3(9.0, 0.0, 9.0).rotated(Vector3.UP, jogador.rotation.y)
	hud.mostrar_area(area.nome_area)
	_lugar = area.nome_area
	await get_tree().process_frame
	_trocando = false
	area_carregada.emit(destino)


func _empurrar_para_tras() -> void:
	var tras := jogador.global_transform.basis.z
	jogador.global_position += Vector3(tras.x, 0.0, tras.z).normalized() * 6.0
	jogador.velocity = Vector3.ZERO


func _ao_vida_do_chefe(nome: String, atual: int, maximo: int) -> void:
	hud.mostrar_chefe(nome, atual, maximo)


func _ao_derrotar_chefe(id: String) -> void:
	derrotados[id] = true
	hud.esconder_chefe()
	var dica := ""
	match id:
		"gorath":
			dica = "\nO Acampamento da Ruptura, a leste do Refúgio, está liberado."
		"kaelor":
			dica = "\nO portal para a Cratera de Ignis se abriu."
		"ignis_maw":
			dica = "\nO portal para Valdoria se abriu."
	if id == "ignis_maw":
		hud.mensagem("Ignis-Maw está livre!\nAs correntes caíram. Pegue a escama e leve à Brenn.", 4.5)
	else:
		hud.mensagem("%s foi derrotado%s" % [NOMES_DOS_CHEFES.get(id, id), dica], 4.5)
	chefe_derrotado.emit(id)
	if id == "solon":
		cena_dialogo([
			["Epílogo", "Solon cai. Os obeliscos começam a se apagar em todas as regiões, um a um."],
			["Epílogo", "Fagulha voa sobre Valdoria enquanto os moradores abrem os portões."],
			["Epílogo", "Brenn começa a desmontar as armas imperiais para fazer ferramentas."],
			["Epílogo", "Torin recusa o trono e ajuda a formar um conselho de moradores, exilados, mineiros e antigos prisioneiros."],
			["Epílogo", "Longe dali, numa região que ninguém visitou, uma pequena luz de Ferro Negro ainda pulsa."],
		], func() -> void:
			hud.mensagem("Fim. O destino dos dragões está nas suas mãos.", 0.0)
			fim_de_jogo.emit())


func _ao_morrer() -> void:
	hud.mensagem("Torin caiu...", 0.0)
	await get_tree().create_timer(2.5).timeout
	jogador.reviver()
	hud.mensagem("", 0.01)
	ir_para("refugio_do_pinhal", "Principal")


func _process(delta: float) -> void:
	if mundo and not _trocando:
		_acompanhar_lugar(delta)
	hud.definir_relogio("%s   %s" % [clima.hora_texto(), Clima.NOMES[clima.tempo]])
	if area == null or _trocando:
		return
	if hud.dialogo_aberto:
		hud.dica("")
		return
	var perto := _npc_mais_perto()
	var objeto := _interagivel_mais_perto()
	if perto and not _objeto_mais_perto_que(objeto, perto):
		hud.dica("E   Falar com %s, %s" % [perto.nome, perto.papel.to_lower()])
		return
	if jogador.montaria:
		hud.dica("E   Desmontar" if (not jogador.montaria.voa or jogador.perto_do_chao()) else "Espaço sobe    C desce    Pouse para desmontar")
		return
	var coisa := _interagivel_mais_perto()
	if coisa:
		hud.dica("E   " + coisa.texto)
		return
	var montar := _montaria_mais_perto()
	hud.dica("E   Montar %s" % montar.nome if montar else "")


## Em que região, povoado ou estrada o Torin está; muda o nome na tela, a região atual e o ar (névoa e cor do céu).
func _acompanhar_lugar(delta: float) -> void:
	var id := mundo.regiao_em(jogador.global_position)
	if id != "" and id != area_nome:
		area = mundo.regioes[id]
		area_nome = id
		hud.esconder_chefe()
	_t_lugar -= delta
	if _t_lugar > 0.0:
		return
	_t_lugar = 0.5
	var lugar := mundo.nome_do_lugar(jogador.global_position)
	if lugar != _lugar:
		_lugar = lugar
		hud.mostrar_area(lugar)
	var estilo := mundo.estilo_em(jogador.global_position)
	if not estilo.is_empty():
		clima.definir_estilo(estilo)


func _npc_mais_perto() -> Npc:
	var melhor: Npc = null
	var dmin := 3.2
	for n: Npc in get_tree().get_nodes_in_group("npcs"):   # todos os NPCs do mundo, não só os da região atual
		var d := n.global_position.distance_to(jogador.global_position)
		if d < dmin:
			dmin = d
			melhor = n
	return melhor


## Depois do resgate a Fagulha acompanha o Torin, pode ser montada e o portão norte abre.
func liberar_fagulha() -> void:
	fagulha_livre = true
	fagulha.visible = true
	fagulha.alvo = jogador
	fagulha.set_physics_process(true)
	fagulha.montaria.ativa = true
	hud.mensagem("Fagulha agora acompanha você.", 4.0)


## O objeto interativo está mais perto do jogador que o NPC? (decide o que o E faz quando os dois estão ao alcance)
func _objeto_mais_perto_que(coisa: Interagivel, npc: Npc) -> bool:
	if coisa == null:
		return false
	return coisa.global_position.distance_to(jogador.global_position) < npc.global_position.distance_to(jogador.global_position)


## A Brenn forja o equipamento reforçado (C3-M1): mais dano de golpe e mais vida máxima.
func _reforcar_equipamento() -> void:
	jogador.dano_golpe += 8
	jogador.vida_max += 20
	jogador.vida = jogador.vida_max
	hud.definir_vida(jogador.vida, jogador.vida_max)
	hud.mensagem("Equipamento reforçado pela Brenn: golpe +8, vida máxima +20.", 5.0)


## A Brenn entrega a lâmina final (C4-M4): mais dano de golpe.
func _forjar_lamina_final() -> void:
	jogador.dano_golpe += 14
	hud.mensagem("Lâmina forjada no fogo: golpe +14.", 5.0)


## Cena de diálogo sem NPC específico: `linhas` é uma lista de [nome, texto]; E avança; no fim chama `ao_fim`.
func cena_dialogo(linhas: Array, ao_fim := Callable()) -> void:
	_cena = linhas
	_cena_i = 0
	_cena_fim = ao_fim
	jogador.travado = true
	hud.dialogo(linhas[0][0], linhas[0][1], 1, linhas.size())


func _avancar_cena() -> void:
	_cena_i += 1
	if _cena_i >= _cena.size():
		hud.fechar_dialogo()
		jogador.travado = false
		_cena = []
		if _cena_fim.is_valid():
			_cena_fim.call()
		return
	hud.dialogo(_cena[_cena_i][0], _cena[_cena_i][1], _cena_i + 1, _cena.size())


func _interagivel_mais_perto() -> Interagivel:
	var melhor: Interagivel = null
	var dmin := 99.0
	for no in get_tree().get_nodes_in_group("interagiveis"):
		var c := no as Interagivel
		if c == null or not c.disponivel():
			continue
		var d := c.global_position.distance_to(jogador.global_position)
		if d < c.raio and d < dmin:
			dmin = d
			melhor = c
	return melhor


func _montaria_mais_perto() -> Montaria:
	var melhor: Montaria = null
	var dmin := 6.0
	for no in get_tree().get_nodes_in_group("montarias"):
		var m := no as Montaria
		if m == null or not m.ativa or m.montada:
			continue
		var d := m.dono.global_position.distance_to(jogador.global_position)
		if d < dmin:
			dmin = d
			melhor = m
	return melhor


func _unhandled_key_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo:
		if evento.physical_keycode == KEY_I:
			_alternar_inventario()
		elif evento.physical_keycode == KEY_M:
			_alternar_mapa()
		elif evento.physical_keycode == KEY_E and not hud.inventario_aberto and not hud.mapa_aberto:
			interagir()


## M abre/fecha o mapa do mundo (as regiões, o que está liberado e a região da missão ativa).
func _alternar_mapa() -> void:
	if hud.dialogo_aberto or jogador.morto or hud.inventario_aberto:
		return
	if hud.mapa_aberto:
		hud.mapa.esconder()
		hud.mapa_aberto = false
		jogador.travado = false
		return
	var liberadas := {}
	var motivos := {}
	for id in AREAS:
		var motivo := ""
		if REQUISITOS.has(id) and not derrotados.has(REQUISITOS[id]):
			motivo = "falta derrotar %s" % NOMES_DOS_CHEFES[REQUISITOS[id]]
		elif REQUISITOS_MISSAO.has(id) and not missoes.concluidas.has(REQUISITOS_MISSAO[id]):
			motivo = "falta a missão %s" % DadosMissoes.MISSOES[REQUISITOS_MISSAO[id]]["titulo"]
		liberadas[id] = motivo == ""
		if motivo != "":
			motivos[id] = motivo
	var missao := ""
	var alvo := ""
	if not missoes.ativas.is_empty():
		missao = DadosMissoes.MISSOES[missoes.ativas[0]]["titulo"]
		alvo = MapaDoMundo.REGIAO_DA_MISSAO.get(missoes.ativas[0], "")
	hud.mapa.mostrar({"atual": area_nome, "alvo": alvo, "liberadas": liberadas, "motivos": motivos, "missao": missao})
	hud.mapa_aberto = true
	jogador.travado = true


## I abre/fecha o inventário: o jogador fica travado e o mouse volta a aparecer enquanto ele está aberto.
func _alternar_inventario() -> void:
	if hud.dialogo_aberto or jogador.morto:
		return
	if hud.inventario_aberto:
		hud.fechar_inventario()
		jogador.travado = false
		if camera.capturar_mouse:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		hud.abrir_inventario()
		jogador.travado = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _ao_usar_item(item: String) -> void:
	if jogador.usar_item(item):
		hud.mensagem("%s: +%d de vida" % [Itens.nome(item), int(Itens.DADOS[item]["cura"])], 1.5)
	elif int(Itens.DADOS[item]["cura"]) > 0:
		hud.mensagem("Vida cheia: não precisa comer agora.", 1.5)


func interagir() -> void:
	if hud.dialogo_aberto and hud.revelando:   # primeiro E: completa o texto que ainda está aparecendo
		hud.completar_dialogo()
		return
	if not _cena.is_empty():
		_avancar_cena()
		return
	if jogador.montaria and not hud.dialogo_aberto:
		if jogador.montaria.voa and not jogador.perto_do_chao():
			hud.mensagem("Pouse (tecla C) para desmontar.", 2.0)
		else:
			jogador.desmontar()
		return
	if hud.dialogo_aberto:
		_dialogo_indice += 1
		if _dialogo_indice >= _falas_atuais.size():
			hud.fechar_dialogo()
			jogador.travado = false
			_dialogo_npc.retomar()
			return
		hud.dialogo(_dialogo_npc.nome + " (" + _dialogo_npc.papel + ")", _falas_atuais[_dialogo_indice], _dialogo_indice + 1, _falas_atuais.size())
		return
	var n := _npc_mais_perto()
	if n != null and _objeto_mais_perto_que(_interagivel_mais_perto(), n):
		n = null   # um objeto interativo (jaula, raiz) está mais perto que o NPC: ele tem prioridade
	if n == null:
		var coisa := _interagivel_mais_perto()
		if coisa:
			coisa.acionar()
			return
		var m := _montaria_mais_perto()
		if m:
			jogador.montar(m)
		return
	missoes.tentar_entrega(n.nome.to_lower())   # maçãs para a Mara etc.
	if n.oferece_missao != "" and missoes.pode_iniciar(n.oferece_missao):
		missoes.iniciar(n.oferece_missao)   # Elda passa a C2-M1, Sava a C2-M2
	_falas_atuais = missoes.dialogo_de(n.nome.to_lower())
	if _falas_atuais.is_empty():
		_falas_atuais = n.falas
	if _falas_atuais.size() == 0:
		return
	_dialogo_npc = n
	GerenciadorMissoes.evento("falar", n.nome.to_lower())
	_dialogo_indice = 0
	jogador.travado = true
	n.olhar_para(jogador.global_position)
	n.pausar()
	hud.dialogo(n.nome + " (" + n.papel + ")", _falas_atuais[0], 1, _falas_atuais.size())
