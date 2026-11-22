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
	hud.definir_vida(jogador.vida, jogador.vida_max)
	ir_para("refugio_do_pinhal", "Principal")


func ir_para(destino: String, spawn: String) -> void:
	if _trocando:
		return
	if REQUISITOS.has(destino) and not derrotados.has(REQUISITOS[destino]):
		hud.mensagem("Caminho bloqueado: derrote %s antes." % NOMES_DOS_CHEFES[REQUISITOS[destino]], 2.5)
		_empurrar_para_tras()
		return
	_trocando = true
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
	fagulha.modo_voo = false
	fagulha.global_position = pos + Vector3(3.0, 0.0, 3.0).rotated(Vector3.UP, jogador.rotation.y)
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
	hud.dica("E   Falar com %s" % perto.nome if perto else "")


func _npc_mais_perto() -> Npc:
	var melhor: Npc = null
	var dmin := 3.2
	for n in area.npcs:
		var d := n.global_position.distance_to(jogador.global_position)
		if d < dmin:
			dmin = d
			melhor = n
	return melhor


func _unhandled_key_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode == KEY_E:
		interagir()


func interagir() -> void:
	if hud.dialogo_aberto:
		_dialogo_indice += 1
		if _dialogo_indice >= _dialogo_npc.falas.size():
			hud.fechar_dialogo()
			jogador.travado = false
			return
		hud.dialogo(_dialogo_npc.nome + " (" + _dialogo_npc.papel + ")", _dialogo_npc.falas[_dialogo_indice])
		return
	var n := _npc_mais_perto()
	if n == null or n.falas.size() == 0:
		return
	_dialogo_npc = n
	_dialogo_indice = 0
	jogador.travado = true
	n.olhar_para(jogador.global_position)
	hud.dialogo(n.nome + " (" + n.papel + ")", n.falas[0])
