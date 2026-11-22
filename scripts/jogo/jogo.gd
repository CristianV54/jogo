class_name Jogo
extends Node3D
## Cena principal: mantém o jogador, o Fagulha, a câmera e a interface, e troca a área do mundo.
## Progresso: cada chefe derrotado liberta o caminho para o próximo. Dá para jogar do início ao fim sem sair daqui.

const AREAS := {
	"refugio_do_pinhal": "res://scenes/areas/refugio_do_pinhal.tscn",
	"bosque_velado": "res://scenes/areas/bosque_velado.tscn",
	"fronteira_ferrogris": "res://scenes/areas/fronteira_ferrogris.tscn",
	"cratera_ignis": "res://scenes/areas/cratera_ignis.tscn",
	"valdoria": "res://scenes/areas/valdoria.tscn",
}
## Quem guarda cada passagem: para entrar na área, é preciso ter derrotado o chefe indicado.
const REQUISITOS := {
	"fronteira_ferrogris": "gorath",
	"cratera_ignis": "kaelor",
	"valdoria": "ignis_maw",
}
const NOMES_DOS_CHEFES := {"gorath": "Brutamontes Gorath", "kaelor": "General Kaelor", "ignis_maw": "Ignis-Maw", "solon": "Imperador Solon"}

signal area_carregada(nome: String)
signal chefe_derrotado(id: String)
signal fim_de_jogo

var area: AreaBase
var area_nome := ""
var derrotados: Dictionary = {}
var missoes: GerenciadorMissoes
var _falas_atuais := PackedStringArray()
var _dialogo_npc: Npc
var _dialogo_indice := 0
var _trocando := false

@onready var jogador: Jogador = $Jogador
@onready var fagulha: Fagulha = $Fagulha
@onready var camera: CameraTerceiraPessoa = $Camera
@onready var hud: Hud = $Interface
@onready var container: Node3D = $AreaAtual


func _ready() -> void:
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
	missoes.missao_concluida.connect(func(_id: String) -> void: hud.definir_rastreador(missoes.rastreador()))
	ir_para("refugio_do_pinhal", "Principal")
	missoes.iniciar("C1-M1")


func ir_para(destino: String, spawn: String) -> void:
	if _trocando:
		return
	if REQUISITOS.has(destino) and not derrotados.has(REQUISITOS[destino]):
		hud.mensagem("Caminho bloqueado: derrote %s antes." % NOMES_DOS_CHEFES[REQUISITOS[destino]], 2.5)
		_empurrar_para_tras()
		return
	_trocando = true
	if jogador.montaria and not jogador.montaria.persistente:
		jogador.desmontar()   # a montaria some com a área antiga
	if area:
		container.remove_child(area)
		area.queue_free()
		area = null
	hud.esconder_chefe()
	var cena: PackedScene = load(AREAS[destino])
	var nova: AreaBase = cena.instantiate()
	container.add_child(nova)
	area = nova
	area_nome = destino
	area.pediu_troca.connect(ir_para)
	if area.has_signal("chefe_vida"):
		area.chefe_vida.connect(_ao_vida_do_chefe)
	if area.has_signal("chefe_morreu"):
		area.chefe_morreu.connect(_ao_derrotar_chefe)
	var t := area.ponto_de_spawn(spawn)
	var pos := t.origin
	pos.y = area.altura_em(pos.x, pos.z) + 0.3
	jogador.global_position = pos
	jogador.rotation.y = t.basis.get_euler().y
	jogador.velocity = Vector3.ZERO
	camera.yaw = jogador.rotation.y
	if not fagulha.montaria.montada:
		fagulha.modo_voo = false
		fagulha.global_position = pos + Vector3(9.0, 0.0, 9.0).rotated(Vector3.UP, jogador.rotation.y)
	hud.mostrar_area(area.nome_area)
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
			dica = "\nA Fortaleza de Ferrogris, a leste do Refúgio, está liberada."
		"kaelor":
			dica = "\nO portal para a Cratera de Ignis se abriu."
		"ignis_maw":
			dica = "\nO portal para Valdoria se abriu."
	hud.mensagem("%s foi derrotado%s" % [NOMES_DOS_CHEFES.get(id, id), dica], 4.5)
	chefe_derrotado.emit(id)
	if id == "solon":
		hud.mensagem("Fim da base jogável. O destino dos dragões está nas suas mãos.", 0.0)
		fim_de_jogo.emit()


func _ao_morrer() -> void:
	hud.mensagem("Torin caiu...", 0.0)
	await get_tree().create_timer(2.5).timeout
	jogador.reviver()
	hud.mensagem("", 0.01)
	ir_para("refugio_do_pinhal", "Principal")


func _process(_delta: float) -> void:
	if area == null or _trocando:
		return
	if hud.dialogo_aberto:
		hud.dica("")
		return
	var perto := _npc_mais_perto()
	if perto:
		hud.dica("E   Falar com %s" % perto.nome)
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


func _npc_mais_perto() -> Npc:
	var melhor: Npc = null
	var dmin := 3.2
	for n in area.npcs:
		var d := n.global_position.distance_to(jogador.global_position)
		if d < dmin:
			dmin = d
			melhor = n
	return melhor


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
		elif evento.physical_keycode == KEY_E and not hud.inventario_aberto:
			interagir()


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
		hud.dialogo(_dialogo_npc.nome + " (" + _dialogo_npc.papel + ")", _falas_atuais[_dialogo_indice])
		return
	var n := _npc_mais_perto()
	if n == null:
		var coisa := _interagivel_mais_perto()
		if coisa:
			coisa.acionar()
			return
		var m := _montaria_mais_perto()
		if m:
			jogador.montar(m)
		return
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
	hud.dialogo(n.nome + " (" + n.papel + ")", _falas_atuais[0])
