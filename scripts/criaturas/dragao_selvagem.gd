class_name DragaoSelvagem
extends Node3D
## Dragão selvagem da Montanha dos Dragões. Usa o mesmo modelo rigado da Fagulha, com outra cor e outro tamanho.
## Dois jeitos de viver: VOANDO em roda de um ponto (sobe e desce, inclina na curva) ou POUSADO numa pedra, parado.
## O pousado pode ser `domavel`: com 3 carnes o Torin ganha a confiança dele (ver DomarDragao) e ele vira montaria.

## Os modelos de dragão do jogo (ver assets/ASSETS.md). `escala`: multiplicador para o modelo ficar no tamanho do jogo
## com tamanho = 1 (cada arquivo vem numa unidade diferente). `sobe`: metros para os pés tocarem o chão.
## `voo` e `parado`: nomes das animações no arquivo (vazio = não tem; fica na pose do arquivo).
const MODELOS := {
	"fagulha": {"cena": "res://assets/models/criaturas/fagulha/fagulha.glb", "escala": 1.0, "sobe": 0.0, "voo": "Fly", "parado": "Idle"},
	"verde": {"cena": "res://assets/models/criaturas/dragoes/quaternius/dragao_verde.fbx", "escala": 1.6, "sobe": 0.0, "voo": "DragonArmature|Dragon_Flying", "parado": "DragonArmature|Dragon_Flying"},
	"terra": {"cena": "res://assets/models/criaturas/dragoes/terra/dragao_da_terra.fbx", "escala": 0.45, "sobe": 0.0, "voo": "", "parado": "", "textura": "res://assets/models/criaturas/dragoes/terra/SbowbgGs.png"},
	"espinhos": {"cena": "res://assets/models/criaturas/dragoes/cethiel/dragon.dae", "escala": 5.2, "sobe": 1.82, "voo": "", "parado": "parado", "anim_parado": "res://assets/models/criaturas/dragoes/cethiel/dragon_idle.dae"},
	"espinhos_negro": {"cena": "res://assets/models/criaturas/dragoes/cethiel/dragon.dae", "escala": 5.2, "sobe": 1.82, "voo": "", "parado": "parado", "anim_parado": "res://assets/models/criaturas/dragoes/cethiel/dragon_idle.dae", "textura": "res://assets/models/criaturas/dragoes/cethiel/dragon_black.png"},
}

var nome := "Dragão selvagem"
var modelo := "fagulha"
var cor := Color(1, 1, 1)
var tamanho := 1.0
var voando := false
var centro := Vector3.ZERO      # voando: o ponto em volta do qual ele gira
var raio := 60.0
var velocidade := 14.0          # m/s ao longo do círculo
var fase := 0.0
var domavel := false
var domado := false
var montaria: Montaria
var _anim: AnimationPlayer
var _t := 0.0


func _ready() -> void:
	add_to_group("dragoes")
	var ficha: Dictionary = MODELOS[modelo]
	var no := (load(String(ficha["cena"])) as PackedScene).instantiate() as Node3D
	no.name = "Modelo"
	add_child(no)
	no.scale = Vector3.ONE * tamanho * float(ficha["escala"])
	no.position.y = float(ficha["sobe"]) * tamanho
	_anim = no.find_child("AnimationPlayer", true, false)
	for mi in no.find_children("*", "MeshInstance3D", true, false):
		var malha := mi as MeshInstance3D
		for i in malha.mesh.get_surface_count():
			var mat := malha.get_active_material(i)
			if mat is StandardMaterial3D:
				var d := mat.duplicate() as StandardMaterial3D
				d.albedo_color = (mat as StandardMaterial3D).albedo_color * cor
				if ficha.has("textura"):   # o arquivo veio sem a pintura ligada, ou esta é outra pele do mesmo modelo
					d.albedo_texture = load(String(ficha["textura"]))
					d.albedo_color = cor
				malha.set_surface_override_material(i, d)
	if ficha.has("anim_parado"):   # a animação vem num arquivo à parte, com o mesmo esqueleto: junta-se ao modelo
		var fonte := (load(String(ficha["anim_parado"])) as PackedScene).instantiate()
		var ap_fonte := fonte.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap_fonte and ap_fonte.get_animation_list().size() > 0:
			var biblioteca := AnimationLibrary.new()
			biblioteca.add_animation("parado", ap_fonte.get_animation(ap_fonte.get_animation_list()[0]).duplicate())
			_anim = AnimationPlayer.new()
			_anim.name = "Animacoes"
			no.add_child(_anim)
			_anim.root_node = NodePath("..")
			_anim.add_animation_library("", biblioteca)
		fonte.free()
	_tocar(String(ficha["voo"]) if voando else String(ficha["parado"]))
	if domavel:
		var domar_no := DomarDragao.new()
		domar_no.name = "Domar"
		domar_no.dragao = self
		domar_no.position = Vector3(0, 1.0, 2.0)
		add_child(domar_no)
	set_process(voando)


func _tocar(animacao: String) -> void:
	if _anim and animacao != "" and _anim.has_animation(animacao) and _anim.current_animation != animacao:
		_anim.get_animation(animacao).loop_mode = Animation.LOOP_LINEAR
		_anim.play(animacao, 0.3)


func _process(delta: float) -> void:
	_t += delta
	var a := fase + _t * velocidade / raio
	var p := centro + Vector3(cos(a) * raio, sin(_t * 0.4 + fase) * 6.0, sin(a) * raio)
	var frente := Vector3(-sin(a), 0.0, cos(a))   # o modelo olha para +Z: vira para onde voa
	global_position = p
	rotation = Vector3(0.0, atan2(frente.x, frente.z), -0.3)   # inclinado para dentro da curva


## O dragão aceita o Torin: passa a ser montaria que voa. `avisar` mostra a fala (falso ao carregar o jogo salvo).
func domar(avisar := true) -> void:
	if domado:
		return
	domado = true
	nome = "Cinza"
	montaria = Montaria.new()
	montaria.nome = nome
	montaria.osso_assento = "paunch"
	montaria.elevacao = 0.3 * tamanho
	montaria.voa = true
	montaria.velocidade_andando = 6.0
	montaria.velocidade_correndo = 12.0
	montaria.velocidade_voo = 18.0
	montaria.velocidade_voo_rapido = 30.0
	montaria.camera_altura = 3.5 * tamanho
	montaria.camera_distancia = 12.0 * tamanho
	add_child(montaria)
	if avisar:
		get_tree().call_group("sons", "tocar", "rugido")
		var jogo := get_tree().get_first_node_in_group("jogo")
		if jogo:
			jogo.cena_dialogo([["Narrador", "O dragão cheira a carne, come devagar e baixa a cabeça até a altura da sua mão."], ["Narrador", "Você domou o seu primeiro dragão. O nome dele é Cinza. Chegue perto e aperte E para montar."]])
