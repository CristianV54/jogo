class_name Npc
extends Node3D
## Personagem não jogável: um humanoide com falas que cumpre uma ROTINA de trabalho em ciclo (anda, trabalha, descansa).
## Como no jogador, o modelo olha para +Z; por isso o visual fica girado 180° e o nó olha para -Z.
##
## Passos da `rotina` (Array de Dictionary), repetidos para sempre:
##   {"ir": Vector3, "vel": 1.5}                                  anda até o ponto (toca Walk)
##   {"fazer": "Sword_Attack", "seg": 9.0, "olhar": Vector3}      trabalha: repete a animação por `seg` segundos, olhando para `olhar`
##   {"esperar": 4.0, "anim": "Idle", "olhar": Vector3}           fica parado nessa animação (olhar é opcional)
## Sem rotina, o NPC fica parado em `animacao`, como antes.

@export var nome := ""
@export var papel := ""
@export var falas: PackedStringArray = []
@export var animacao := "Idle"
@export var cena: PackedScene
@export var rotina: Array = []

const PROTESTOS := ["Ei! Calma!", "Está louco?! Guarde essa espada!", "Pare com isso, Torin!", "Isso dói!", "Eu sou do seu bando!"]

var visual: Humanoide
var raio_colisao := 0.5
var morto := false   # os NPCs da história nunca morrem; só reagem
var altura_em: Callable   # (x, z) -> altura do chão; se vazio, o NPC fica em y = 0
var corpo: AnimatableBody3D

var _protesto: Label3D
var _passo := -1
var _restante := 0.0
var _preso := 0.0
var _pausas := 0          # > 0: conversando ou levando um golpe; a rotina espera


func _ready() -> void:
	visual = cena.instantiate()
	visual.animacao_inicial = animacao
	visual.rotation_degrees.y = 180.0
	add_child(visual)
	name = nome if nome != "" else name
	add_to_group("atingiveis")
	corpo = Solidos.corpo_movel(self, AABB(Vector3(-0.35, 0.0, -0.35), Vector3(0.7, 1.8, 0.7)))   # o jogador não atravessa as pessoas
	if not rotina.is_empty():
		_proximo_passo()


func olhar_para(alvo: Vector3) -> void:
	var d := alvo - global_position
	rotation.y = atan2(-d.x, -d.z)


## A rotina espera enquanto o jogador conversa com o NPC (e o NPC olha para ele).
func pausar() -> void:
	_pausas += 1
	visual.tocar("Idle", 0.2)


func retomar() -> void:
	_pausas = maxi(0, _pausas - 1)
	if _pausas == 0 and _passo >= 0:
		_entrar_no_passo()   # recomeça a animação do passo atual


func _physics_process(delta: float) -> void:
	if rotina.is_empty() or _pausas > 0 or _passo < 0:
		return
	var p: Dictionary = rotina[_passo]
	if p.has("ir"):
		_andar(p, delta)
	else:
		_restante -= delta
		var anim: String = p.get("fazer", p.get("anim", "Idle"))
		if p.has("fazer") and not visual.animacoes.is_playing():
			visual.animacoes.play(anim, 0.15)   # golpe do ferreiro/lenhador: recomeça ao terminar
		if _restante <= 0.0:
			_proximo_passo()


func _andar(p: Dictionary, delta: float) -> void:
	var destino: Vector3 = p["ir"]
	var ate := destino - global_position
	ate.y = 0.0
	if ate.length() < 0.25:
		_proximo_passo()
		return
	var dir := ate.normalized()
	if _caminho_livre(dir):
		_preso = 0.0
		global_position += dir * float(p.get("vel", 1.5)) * delta
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 6.0 * delta)
		visual.tocar("Walk", 0.2)
		if altura_em.is_valid():
			global_position.y = altura_em.call(global_position.x, global_position.z)
	else:   # alguém no caminho (o jogador, um animal): espera um pouco e, se não sair, pula este passo
		_preso += delta
		visual.tocar("Idle", 0.2)
		if _preso > 3.0:
			_preso = 0.0
			_proximo_passo()


## Raios à frente contra o mundo e outros seres (camadas 1 e 8), partindo da altura do peito.
func _caminho_livre(dir: Vector3) -> bool:
	var de := global_position + Vector3(0.0, 0.9, 0.0)
	var q := PhysicsRayQueryParameters3D.create(de, de + dir * 0.9, 1 | Solidos.CAMADA_SERES)
	q.exclude = [corpo.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _proximo_passo() -> void:
	_passo = (_passo + 1) % rotina.size()
	_entrar_no_passo()


func _entrar_no_passo() -> void:
	var p: Dictionary = rotina[_passo]
	_preso = 0.0
	if p.has("ir"):
		return   # a animação Walk entra no primeiro quadro de _andar
	_restante = float(p.get("seg", p.get("esperar", 3.0)))
	if p.has("olhar"):
		olhar_para(p["olhar"])
	var anim: String = p.get("fazer", p.get("anim", "Idle"))
	visual.animacoes.play(anim, 0.2)


## Leva um golpe: pisca em vermelho, se encolhe e reclama. Não perde vida nem morre.
func receber_dano(_quantidade: int, _de: Node3D = null) -> void:
	Efeitos.piscar(visual)
	_pausas += 1
	visual.animacoes.play("Hit_Chest", 0.05)
	if _protesto == null:
		_protesto = Label3D.new()
		_protesto.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_protesto.position = Vector3(0.0, 2.3, 0.0)
		_protesto.font_size = 48
		_protesto.pixel_size = 0.006
		_protesto.outline_size = 12
		_protesto.no_depth_test = true
		add_child(_protesto)
	_protesto.text = PROTESTOS[randi() % PROTESTOS.size()]
	_protesto.visible = true
	await get_tree().create_timer(0.7).timeout
	if rotina.is_empty():
		visual.tocar(animacao, 0.2)
	retomar()
	await get_tree().create_timer(1.6).timeout
	_protesto.visible = false
