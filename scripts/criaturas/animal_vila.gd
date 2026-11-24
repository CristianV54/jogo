class_name AnimalVila
extends Node3D
## Animal de vila/fazenda: fica parado um tempo, anda até um ponto perto de casa, para de novo.
## Leva golpes: foge e, se a vida zera, tomba. Se `montavel`, o jogador pode montá-lo (ver Montaria).
## O modelo olha para +Z (como o Fagulha). Sem colisão: não bloqueia o jogador.

@export var modelo: PackedScene
@export var nome := "Animal"
@export var raio_vagar := 4.0
@export var velocidade := 1.0
@export var anim_parado := "Idle"
@export var anim_andar := "WalkSlow"
@export var giro := 4.0
@export var vida_max := 20
@export var raio_colisao := 0.6       # alcance do golpe do jogador contra este animal
@export var montavel := false
@export var escala := 1.0          # tamanho do visual (cervo = cavalo menor, coelho = cão pequeno)
@export var fugitivo := false      # foge quando o jogador chega perto (cervo, coelho)
@export var raio_fuga := 9.0
@export var acessorio := ""        # chifres, orelhas (ver Acessorios)
@export var especie := ""           # chave de VariacaoDeCores
@export var drops := {}               # {item: [mínimo, máximo]} largados ao morrer

var altura_em: Callable   # (x, z) -> altura do chão; se vazio, o animal fica em y = 0
var vida := 0
var morto := false
var montaria: Montaria
var corpo: AnimatableBody3D            # corpo sólido: o jogador não o atravessa (some com o animal morto ou montado)

var _casa := Vector3.ZERO
var _destino := Vector3.ZERO
var _espera := 0.0
var _andando := false
var _fuga := 0.0
var _dir_fuga := Vector3.ZERO
var _anim: AnimationPlayer
var _visual: Node3D
var _cabeca: Node3D                   # se o modelo tiver um nó "Cabeca" (galinha), ele bica o chão parado
var _bicar := 1.5


func _ready() -> void:
	_visual = modelo.instantiate()
	_visual.scale = Vector3.ONE * escala
	add_child(_visual)
	_anim = _visual.find_child("AnimationPlayer", true, false)
	_cabeca = _visual.find_child("Cabeca", true, false) as Node3D
	VariacaoDeCores.aplicar(_visual, especie)
	Acessorios.aplicar(_visual, acessorio)
	Olhos.aplicar(_visual, especie)
	var caixa := Solidos.caixa_de(_visual, 0.8)
	corpo = Solidos.corpo_movel(self, AABB(caixa.position * escala, caixa.size * escala))
	_casa = position
	_espera = randf_range(0.5, 4.0)
	vida = vida_max
	add_to_group("atingiveis")
	add_to_group("animais")
	if montavel:
		montaria = Montaria.new()
		montaria.nome = nome
		montaria.osso_assento = "Torso"
		montaria.elevacao = 0.2
		montaria.velocidade_andando = 6.0
		montaria.velocidade_correndo = 13.0
		montaria.forca_pulo = 8.5
		montaria.camera_altura = 2.3
		montaria.camera_distancia = 6.5
		add_child(montaria)
	_tocar(anim_parado)


var _verificado := false


## Na primeira vez que o bicho está ativo (a física da região só existe com a região ligada), se nasceu dentro de uma pedra,
## tronco ou parede, procura o ponto livre mais perto em anéis crescentes e vai para lá.
func _desencravar() -> void:
	_verificado = true
	var raio := maxf(raio_colisao, 0.5) * 0.9
	var chao: float = altura_em.call(position.x, position.z) if altura_em.is_valid() else global_position.y
	if _livre_em(Vector3(global_position.x, chao + 0.7, global_position.z), raio):
		return
	for anel in [1.5, 3.0, 4.5, 6.0, 9.0]:
		for k in 12:
			var ang := TAU * k / 12.0
			var d: Vector3 = Vector3(cos(ang), 0.0, sin(ang)) * anel
			var alvo_local: Vector3 = position + d
			var chao2: float = altura_em.call(alvo_local.x, alvo_local.z) if altura_em.is_valid() else global_position.y
			if _livre_em(global_position + d + Vector3(0.0, chao2 - global_position.y + 0.7, 0.0), raio):
				position = alvo_local
				_casa = position
				return


func _livre_em(centro: Vector3, raio: float) -> bool:
	var esfera := SphereShape3D.new()
	esfera.radius = raio
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = esfera
	q.transform = Transform3D(Basis.IDENTITY, centro)
	q.collision_mask = 1 | Solidos.CAMADA_SERES
	q.exclude = [corpo.get_rid()]
	for r in get_world_3d().direct_space_state.intersect_shape(q, 4):
		if String((r.collider as Node).name) != "Colisao":
			return false
	return true


func _physics_process(delta: float) -> void:
	if not _verificado:
		_desencravar()
	var livre_de_corpo := morto or (montaria != null and montaria.montada)   # morto ou montado: sem corpo (o cavaleiro mora dentro dele)
	corpo.collision_layer = 0 if livre_de_corpo else Solidos.CAMADA_SERES
	if livre_de_corpo:
		return
	if fugitivo and _fuga <= 0.0:
		var j := get_tree().get_first_node_in_group("jogador") as Node3D
		if j:
			var d := global_position - j.global_position
			d.y = 0.0
			if d.length() < raio_fuga:
				_dir_fuga = d.normalized()
				_fuga = 2.5
	if _fuga > 0.0:
		_fuga -= delta
		if not _caminho_livre(_dir_fuga):   # bateu numa parede/cerca: tenta desviar para um lado, senão para de fugir
			var lado := _dir_fuga.rotated(Vector3.UP, PI / 2.0)
			if _caminho_livre(lado):
				_dir_fuga = lado
			elif _caminho_livre(-lado):
				_dir_fuga = -lado
			else:
				_fuga = 0.0
		if _fuga > 0.0:
			position += _dir_fuga * velocidade * 4.0 * delta
		rotation.y = lerp_angle(rotation.y, atan2(_dir_fuga.x, _dir_fuga.z), giro * 2.0 * delta)
		_tocar("Run" if _tem("Run") else anim_andar)
		if _fuga <= 0.0:
			_casa = position   # volta a vagar a partir de onde parou
			_andando = false
			_espera = randf_range(1.0, 3.0)
			_tocar(anim_parado)
	elif _andando:
		var ate := _destino - position
		ate.y = 0.0
		if ate.length() < 0.25:
			_andando = false
			_espera = randf_range(3.0, 9.0)
			_tocar(anim_parado)
		else:
			var direcao := ate.normalized()
			if _caminho_livre(direcao):
				position += direcao * velocidade * delta
				rotation.y = lerp_angle(rotation.y, atan2(direcao.x, direcao.z), giro * delta)
			else:   # algo no caminho: para e escolhe outro rumo depois
				_andando = false
				_espera = randf_range(1.0, 2.5)
				_tocar(anim_parado)
	else:
		_espera -= delta
		if _espera <= 0.0:
			for tentativa in 6:   # só aceita um rumo cujo caminho está livre
				var ang := randf() * TAU
				var dir := Vector3(cos(ang), 0.0, sin(ang))
				var dist := randf_range(0.4, 1.0) * raio_vagar
				if _caminho_livre(dir, dist):
					_destino = _casa + dir * dist
					_andando = true
					_tocar(anim_andar)
					break
			if not _andando:
				_espera = randf_range(1.0, 2.5)
	if _cabeca and not _andando and _fuga <= 0.0:
		_bicar -= delta
		if _bicar <= 0.0:
			_bicar = randf_range(1.2, 3.5)
			var tw := create_tween()
			tw.tween_property(_cabeca, "rotation:x", 1.0, 0.18)
			tw.tween_property(_cabeca, "rotation:x", 0.0, 0.22)
	if altura_em.is_valid():
		position.y = altura_em.call(position.x, position.z)


## Há espaço para andar nessa direção? Três raios (centro e lados do corpo) contra o mundo (camada 1: paredes,
## cercas, troncos, portas fechadas, terreno). `distancia` 0 = só a folga do corpo.
func _caminho_livre(direcao: Vector3, distancia := 0.0) -> bool:
	var chao: float = altura_em.call(position.x, position.z) if altura_em.is_valid() else global_position.y   # altura_em usa as coordenadas do pai (a área)
	var raio := maxf(raio_colisao, 0.5) * 0.9
	return Solidos.caminho_livre(self, Vector3(global_position.x, chao + 0.7, global_position.z), direcao, maxf(distancia, 0.0) + raio + 0.4, raio, [corpo.get_rid()])


func receber_dano(quantidade: int, de: Node3D = null) -> void:
	if morto:
		return
	vida = maxi(0, vida - quantidade)
	Efeitos.piscar(_visual)
	if vida <= 0:
		morto = true
		if montaria:
			montaria.ativa = false
		if _tem("Death"):
			_anim.play("Death", 0.1)
		else:   # sem animação de morte (galinha): tomba de lado
			create_tween().tween_property(_visual, "rotation_degrees:z", 90.0, 0.35)
		Pickup.largar(get_parent(), global_position, drops)
		await get_tree().create_timer(5.0).timeout
		Efeitos.desintegrar(self, _visual)
		return
	var longe := global_position - (de.global_position if de else global_position - Vector3.FORWARD)
	longe.y = 0.0
	_dir_fuga = longe.normalized() if longe.length() > 0.01 else Vector3.FORWARD
	_fuga = 3.0


func _tem(nome_anim: String) -> bool:
	return _anim != null and _anim.has_animation(nome_anim)


func _tocar(nome_anim: String) -> void:
	if _anim and _anim.has_animation(nome_anim) and _anim.current_animation != nome_anim:
		_anim.play(nome_anim, 0.3)
