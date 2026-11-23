class_name Fagulha
extends Node3D
## Fagulha acompanha o alvo: parado perto, andando a distância média, correndo quando longe.
## Tecla F alterna o voo (sobe e paira em cima do alvo). O modelo olha para +Z (medido com a cabeça e a pélvis).

@export var alvo: Node3D
@export var distancia_parar := 8.0
@export var distancia_correr := 18.0
@export var velocidade_andando := 5.0
@export var velocidade_correndo := 10.0
@export var velocidade_voo := 9.0
@export var altura_voo := 8.0
@export var velocidade_subida := 5.0
@export var giro := 6.0

## As três fases do Fagulha (cada uma muda tamanho, cor, voo, ataque e se pode ser montado):
##   1 ferido    (após o resgate, C1-M4): segue no chão, não voa, morde de leve o que chega perto
##   2 jovem     (após a queda do Primeiro Obelisco, C2-M3): plana a 3 m por alguns segundos, morde mais forte
##   3 alado     (após a Fortaleza de Ferrogris, C3-M4): voo livre, pode ser montado, cospe fogo
const ESCALA_DA_FASE := {1: 0.7, 2: 0.85, 3: 1.0}
const COR_DA_FASE := {1: Color(0.62, 0.56, 0.56), 2: Color(0.84, 0.78, 0.78), 3: Color(1, 1, 1)}   # as marcas do Ferro Negro vão sumindo
const DANO_DA_FASE := {1: 4, 2: 9, 3: 16}
const ALCANCE_DA_FASE := {1: 3.0, 2: 4.5, 3: 9.0}
const INTERVALO_DA_FASE := {1: 2.2, 2: 1.8, 3: 4.0}
const ALTURA_PLANADO := 3.0
const TEMPO_PLANADO := 6.0
const RECARGA_PLANADO := 4.0

var fase := 3   # o Jogo põe 1 depois do resgate; fora do jogo (cenas de teste) vale a fase completa
var modo_voo := false
var _t_ataque := 0.0
var _t_planado := 0.0
var _t_recarga := 0.0
var _materiais_base: Array = []   # [MeshInstance3D, índice da superfície, material original]
var montaria: Montaria
var corpo: AnimatableBody3D            # tronco sólido (as asas não bloqueiam); some enquanto está montada
var animacao_atual := ""

@onready var _modelo: Node3D = $Modelo
var _anim: AnimationPlayer


func _ready() -> void:
	_anim = _modelo.find_child("AnimationPlayer", true, false)
	montaria = Montaria.new()
	montaria.nome = "Fagulha"
	montaria.osso_assento = "paunch"
	montaria.elevacao = 0.3
	montaria.voa = true
	montaria.persistente = true
	montaria.velocidade_andando = 6.0
	montaria.velocidade_correndo = 12.0
	montaria.velocidade_voo = 16.0
	montaria.velocidade_voo_rapido = 28.0
	montaria.camera_altura = 3.5
	montaria.camera_distancia = 12.0
	add_child(montaria)
	corpo = Solidos.corpo_movel(self, AABB(Vector3(-0.8, 0.0, -2.8), Vector3(1.6, 1.9, 4.6)))
	for mi in _modelo.find_children("*", "MeshInstance3D", true, false):
		for i in (mi as MeshInstance3D).mesh.get_surface_count():
			var mat := (mi as MeshInstance3D).get_active_material(i)
			if mat is StandardMaterial3D:
				_materiais_base.append([mi, i, mat])
	definir_fase(fase)
	_tocar("Idle")


## Muda de fase: tamanho, cor e se pode ser montada (só na fase 3). `cena` mostra a fala da transformação.
func definir_fase(nova: int, cena := false) -> void:
	fase = clampi(nova, 1, 3)
	var e: float = ESCALA_DA_FASE[fase]
	if _modelo:
		_modelo.scale = Vector3.ONE * e
	var tinta: Color = COR_DA_FASE[fase]
	for item in _materiais_base:
		var d := (item[2] as StandardMaterial3D).duplicate() as StandardMaterial3D
		d.albedo_color = (item[2] as StandardMaterial3D).albedo_color * tinta
		(item[0] as MeshInstance3D).set_surface_override_material(item[1], d)
	if montaria:
		var jogo := get_tree().get_first_node_in_group("jogo") if is_inside_tree() else null
		montaria.ativa = fase >= 3 and (jogo == null or bool(jogo.get("fagulha_livre")))
	if fase < 2:
		modo_voo = false
	if cena and is_inside_tree():
		var jogo2 := get_tree().get_first_node_in_group("jogo")
		if jogo2:
			jogo2.cena_dialogo(_FALAS_DA_FASE[fase])


const _FALAS_DA_FASE := {
	1: [["Narrador", "Fagulha ergue a cabeça. Ainda manca, e as marcas do Ferro Negro riscam as escamas, mas já segue você."]],
	2: [["Narrador", "O obelisco desaba e Fagulha estremece. As marcas do Ferro Negro começam a clarear nas escamas."], ["Narrador", "As asas se abrem pela primeira vez, ainda trêmulas. Ele já consegue planar alguns metros. Aperte F para planar."]],
	3: [["Narrador", "Fagulha abre as asas inteiras e ruge. Os cativos de Ferrogris olham para o céu, e as últimas marcas desaparecem."], ["Narrador", "Agora ele voa livre, cospe fogo e carrega você nas costas. Aperte E perto dele para montar."]],
}


func _unhandled_key_input(evento: InputEvent) -> void:
	if montaria.montada:
		return
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode == KEY_F:
		if fase < 2:
			var hud = get_tree().get_first_node_in_group("jogo").get("hud") if get_tree().get_first_node_in_group("jogo") else null
			if hud:
				hud.mensagem("Fagulha ainda está ferido demais para voar.", 2.5)
			return
		if fase == 2 and not modo_voo and _t_recarga > 0.0:
			return   # descansando: ainda não planou de novo
		modo_voo = not modo_voo
		_t_planado = 0.0


func _physics_process(delta: float) -> void:
	corpo.collision_layer = 0 if montaria.montada else Solidos.CAMADA_SERES
	if montaria.montada or alvo == null:
		return
	var ate := alvo.global_position - global_position
	var plano := Vector3(ate.x, 0.0, ate.z)
	var distancia := plano.length()

	var nome := "Idle"
	var velocidade := 0.0
	if modo_voo:
		nome = "Fly"
		velocidade = velocidade_voo if distancia > distancia_parar else 0.0
	elif distancia > distancia_correr:
		nome = "Run"
		velocidade = velocidade_correndo
	elif distancia > distancia_parar:
		nome = "Walk"
		velocidade = velocidade_andando

	if velocidade > 0.0:
		var direcao := plano.normalized()
		global_position += direcao * minf(velocidade * delta, distancia)
		rotation.y = lerp_angle(rotation.y, atan2(direcao.x, direcao.z), giro * delta)

	var altura := (altura_voo if fase >= 3 else ALTURA_PLANADO) if modo_voo else 0.0
	if modo_voo and fase == 2:
		_t_planado += delta
		if _t_planado >= TEMPO_PLANADO:   # a fase 2 só plana por alguns segundos e pousa
			modo_voo = false
			_t_recarga = RECARGA_PLANADO
	_t_recarga = maxf(0.0, _t_recarga - delta)
	global_position.y = move_toward(global_position.y, altura, velocidade_subida * delta)
	_tocar(nome)
	_atacar(delta)


## Defende o Torin: morde (fases 1 e 2) ou cospe fogo (fase 3) em quem está perseguindo ou atacando perto dele.
func _atacar(delta: float) -> void:
	_t_ataque -= delta
	if _t_ataque > 0.0 or alvo == null:
		return
	var alcance: float = ALCANCE_DA_FASE[fase]
	var melhor: Inimigo = null
	var dmin := alcance
	for e in get_tree().get_nodes_in_group("inimigos"):
		var ini := e as Inimigo
		if ini == null or ini.estado == Inimigo.Estado.MORTO or ini.estado == Inimigo.Estado.PARADO:
			continue
		if ini.global_position.distance_to(alvo.global_position) > alcance + 6.0:
			continue   # só defende quem está perto do Torin
		var d := ini.global_position.distance_to(global_position)
		if d < dmin:
			dmin = d
			melhor = ini
	if melhor == null:
		return
	_t_ataque = INTERVALO_DA_FASE[fase]
	var para := melhor.global_position - global_position
	rotation.y = atan2(para.x, para.z)
	melhor.receber_dano(int(DANO_DA_FASE[fase]), self)
	if fase >= 3:   # fogo de verdade sobre o alvo, só visual (o dano já foi dado)
		var f := Fogo.new()
		f.escala = 1.2
		f.com_fumaca = false
		f.energia_luz = 3.0
		f.alcance_luz = 8.0
		melhor.get_parent().add_child(f)
		f.global_position = melhor.global_position
		get_tree().create_timer(1.4).timeout.connect(func() -> void:
			if is_instance_valid(f):
				f.queue_free())


func _tocar(nome: String) -> void:
	if nome != animacao_atual and _anim:
		_anim.play(nome, 0.3)
		animacao_atual = nome
