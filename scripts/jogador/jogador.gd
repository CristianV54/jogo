class_name Jogador
extends CharacterBody3D
## Corpo do jogador (Torin): anda e corre em relação à câmera (WASD, Shift), pula (Espaço), golpeia (J ou clique),
## rola (K) e leva dano.
## O visual é o Torin real; o modelo olha para +Z, então o nó Visual fica girado 180° para olhar para a frente (-Z).
## A entrada pode ser forçada por código, só para os testes automáticos.

signal vida_mudou(atual: int, maximo: int)
signal morreu
signal item_coletado(item: String, quantidade: int, inventario: Dictionary)
signal inventario_mudou(inventario: Dictionary)
signal fome_mudou(atual: float)
signal equipamento_mudou(equipado: Dictionary)
signal acertou   # o golpe pegou em alguém (o som do acerto escuta isto)

@export var camera: CameraTerceiraPessoa
@export var velocidade_andando := 4.0
@export var velocidade_correndo := 7.0
@export var gravidade := 20.0
@export var giro := 10.0
@export var vida_max := 100
@export var dano_golpe := 22
@export var alcance_golpe := 2.4
@export var momento_do_golpe := 0.5     # segundos depois do início de Sword_Attack em que a lâmina acerta
@export var duracao_golpe := 1.0
@export var forca_pulo := 7.5               # com gravidade 20: sobe ~1,4 m
@export var velocidade_rolamento := 9.0
@export var duracao_rolamento := 0.65
@export var regeneracao_apos := 4.0        # segundos sem levar dano para começar a recuperar vida

var entrada_forcada := Vector2.ZERO   # x: direita(+), y: trás(+). Zero = usa o teclado.
var correndo_forcado := false
var animacao_atual := ""
var vida := 100
var inventario := {}                   # {id do item: quantidade}
var fome := 100.0                      # 100 = saciado; cai com o tempo (mais correndo); a zero o Torin perde vida
var equipado := {"arma": "espada_curta", "armadura": ""}
var defesa := 0.0                      # fração do dano que a armadura tira
var _t_fome := 0.0
var _comendo := 0.0
var _travou_para_comer := false   # o gesto de comer só destrava o Torin se foi ele que travou (com o inventário aberto, quem trava é a janela)
var travado := false                   # diálogo aberto ou cena especial: não anda nem golpeia
var morto := false
var _golpeando := false
var _rolando := false
var _dir_rolamento := Vector3.ZERO
var _sem_dano := 0.0
var _pulo_pedido := false
var _tempo_no_ar := 0.0
var _pouso := 0.0
var _estava_no_chao := true
var _regen := 0.0
var _invulneravel := 0.0
var _reacao := 0.0
var montaria: Montaria = null            # criatura que o jogador está montando (cavalo, Fagulha)
var _voando := false
var _transicao := 0.0                    # > 0: está subindo na montaria (animação de montar)
var _inicio_montar := Vector3.ZERO       # onde o cavaleiro estava ao começar a subir
var _saindo := 0.0                       # > 0: está descendo da montaria (não anda ainda)
const DURACAO_MONTAR := 0.9
const DURACAO_DESMONTAR := 0.7
var _camera_antes := Vector2.ZERO        # altura do foco e distância da câmera antes de montar
const QUADRIL_SENTADO := 0.5             # altura do quadril de Sitting_Idle acima dos pés do modelo

@onready var visual: Humanoide = $Visual


func _ready() -> void:
	vida = vida_max
	collision_mask |= ConstrutorCasa.CAMADA_MOVEIS | Solidos.CAMADA_SERES   # móveis das casas, animais, pessoas e o Fagulha
	add_to_group("jogador")


func _physics_process(delta: float) -> void:
	_passar_fome(delta)
	_invulneravel = maxf(0.0, _invulneravel - delta)
	_reacao = maxf(0.0, _reacao - delta)
	_saindo = maxf(0.0, _saindo - delta)
	_pouso = maxf(0.0, _pouso - delta)
	_regenerar(delta)
	if montaria != null:
		_mover_montado(delta)
		return
	var entrada := Vector2.ZERO
	var correndo := false
	if not travado and not morto and not _golpeando and _reacao <= 0.0 and _saindo <= 0.0:
		entrada = _ler_entrada()
		correndo = correndo_forcado or Input.is_physical_key_pressed(KEY_SHIFT)
	var yaw := camera.yaw if camera else 0.0
	var direcao := Vector3(entrada.x, 0.0, entrada.y).rotated(Vector3.UP, yaw)
	var velocidade := velocidade_correndo if correndo else velocidade_andando

	velocity.x = direcao.x * velocidade
	velocity.z = direcao.z * velocidade
	if _rolando:
		velocity.x = _dir_rolamento.x * velocidade_rolamento
		velocity.z = _dir_rolamento.z * velocidade_rolamento
	if _pulo_pedido and is_on_floor() and not travado and not morto and not _golpeando and not _rolando:
		velocity.y = forca_pulo   # pulo para CIMA; o movimento horizontal continua o que o jogador está fazendo
		_tempo_no_ar = 0.0
	elif is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravidade * delta
	_pulo_pedido = false
	move_and_slide()
	if is_on_floor():
		if not _estava_no_chao:
			_pouso = 0.3
		_tempo_no_ar = 0.0
	else:
		_tempo_no_ar += delta
	_estava_no_chao = is_on_floor()

	if direcao.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direcao.x, -direcao.z), giro * delta)
	if not _golpeando and not _rolando and not morto and _reacao <= 0.0 and _saindo <= 0.0:
		_animar(direcao.length(), correndo)


func _unhandled_input(evento: InputEvent) -> void:
	if travado or morto:
		return
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode == KEY_J:
		golpear()
	elif evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode == KEY_SPACE:
		pular()
	elif evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode == KEY_K:
		rolar()
	elif evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		golpear()


func _animar(movimento: float, correndo: bool) -> void:
	var nome := "Idle"
	if not is_on_floor():
		nome = "Jump_Start" if _tempo_no_ar < 0.25 and velocity.y > 0.0 else "Jump"
	elif _pouso > 0.0 and movimento < 0.01:
		nome = "Jump_Land"
	elif movimento > 0.01:
		nome = "Sprint" if correndo else "Jog_Fwd"
	if nome != animacao_atual:
		visual.tocar(nome)
		animacao_atual = nome


## Pulo: sobe na vertical e segue com o movimento horizontal atual.
func pular() -> void:
	if montaria == null or montaria.forca_pulo > 0.0:
		_pulo_pedido = true


## Golpe de espada: toca Sword_Attack e, no momento do impacto, fere os inimigos à frente.
func golpear() -> void:
	if _golpeando or morto or travado or montaria != null:
		return
	_golpeando = true
	animacao_atual = "Sword_Attack"
	visual.tocar("Sword_Attack", 0.05)
	await get_tree().create_timer(momento_do_golpe).timeout
	if not morto:
		_acertar()
	await get_tree().create_timer(maxf(0.0, duracao_golpe - momento_do_golpe)).timeout
	_golpeando = false
	animacao_atual = ""


## Rolamento: desliza por 0,65 s na direção do movimento (ou para onde olha) e fica invulnerável nesse tempo.
func rolar() -> void:
	if _rolando or _golpeando or morto or travado or montaria != null:
		return
	var entrada := _ler_entrada()
	var yaw := camera.yaw if camera else 0.0
	var dir := Vector3(entrada.x, 0.0, entrada.y).rotated(Vector3.UP, yaw)
	if dir.length() < 0.1:
		dir = -global_transform.basis.z
	_dir_rolamento = Vector3(dir.x, 0.0, dir.z).normalized()
	rotation.y = atan2(-_dir_rolamento.x, -_dir_rolamento.z)
	_rolando = true
	_invulneravel = maxf(_invulneravel, duracao_rolamento)
	animacao_atual = "Roll"
	visual.tocar("Roll", 0.05)
	await get_tree().create_timer(duracao_rolamento).timeout
	_rolando = false
	animacao_atual = ""


func _regenerar(delta: float) -> void:
	_sem_dano += delta
	if morto or vida >= vida_max or _sem_dano < regeneracao_apos or fome < 20.0:   # com muita fome a vida não volta sozinha
		return
	_regen += delta
	if _regen >= 0.5:
		_regen = 0.0
		vida = mini(vida_max, vida + 1)
		vida_mudou.emit(vida, vida_max)


func _acertar() -> void:
	var frente := -global_transform.basis.z
	var pegou := false
	for no in get_tree().get_nodes_in_group("inimigos"):
		var ini: Inimigo = no as Inimigo
		if ini == null or ini.estado == Inimigo.Estado.MORTO:
			continue
		var d := ini.global_position - global_position
		d.y = 0.0
		var raio := alcance_golpe + ini.raio_colisao
		if d.length() <= raio and (d.length() < 0.5 or frente.dot(d.normalized()) > 0.1):
			ini.receber_dano(dano_golpe, self)
			pegou = true
	for no in get_tree().get_nodes_in_group("atingiveis"):   # animais e pessoas: reagem ao golpe
		var alvo := no as Node3D
		if alvo == null or no.get("morto") == true:
			continue
		var d2 := alvo.global_position - global_position
		d2.y = 0.0
		var raio2 := alcance_golpe + float(no.get("raio_colisao"))
		if d2.length() <= raio2 and (d2.length() < 0.5 or frente.dot(d2.normalized()) > 0.1):
			no.receber_dano(dano_golpe, self)
			pegou = true
	if pegou:
		acertou.emit()


func receber_dano(quantidade: int, _de: Node3D = null) -> void:
	if morto or _invulneravel > 0.0:
		return
	vida = maxi(0, vida - maxi(1, int(round(quantidade * (1.0 - defesa)))))
	_sem_dano = 0.0
	_invulneravel = 0.7
	vida_mudou.emit(vida, vida_max)
	if vida <= 0:
		desmontar()
		morto = true
		animacao_atual = "Death01"
		visual.tocar("Death01", 0.05)
		morreu.emit()
	else:
		_reacao = 0.45
		animacao_atual = "Hit_Chest"
		visual.tocar("Hit_Chest", 0.05)


func coletar(item: String, quantidade: int) -> void:
	inventario[item] = int(inventario.get(item, 0)) + quantidade
	item_coletado.emit(item, quantidade, inventario)
	GerenciadorMissoes.evento("coletar", item, quantidade)
	inventario_mudou.emit(inventario)


## Tira `quantidade` do item do inventário (para entregas). Devolve false se não houver o bastante.
func gastar_item(item: String, quantidade: int) -> bool:
	if int(inventario.get(item, 0)) < quantidade:
		return false
	inventario[item] = int(inventario[item]) - quantidade
	if int(inventario[item]) <= 0:
		inventario.erase(item)
	inventario_mudou.emit(inventario)
	return true


## A fome cai sozinha (uns 25 minutos parado para ir de 100 a 0; correndo, o dobro). A zero, o Torin perde 1 de vida a
## cada 4 segundos, até comer.
func _passar_fome(delta: float) -> void:
	if morto:
		return
	var antes := int(fome)
	var gasto := 0.066 * (2.0 if Vector2(velocity.x, velocity.z).length() > velocidade_andando + 1.0 else 1.0)
	fome = maxf(0.0, fome - gasto * delta)
	if int(fome) != antes:
		fome_mudou.emit(fome)
	if fome <= 0.0:
		_t_fome += delta
		if _t_fome >= 4.0:
			_t_fome = 0.0
			var d := defesa
			defesa = 0.0   # fome não é golpe: a armadura não protege
			receber_dano(1)
			defesa = d
	if _comendo > 0.0:
		_comendo -= delta
		if _comendo <= 0.0:
			if _travou_para_comer:
				travado = false
			animacao_atual = ""


## Usa um item da bolsa. Comida: o Torin para, leva a mão à boca (animação Interact) e recupera vida e fome. Arma ou
## armadura: equipa (ou tira, se já era a equipada). Devolve false se não deu.
func usar_item(item: String) -> bool:
	var dados: Dictionary = Itens.DADOS.get(item, {})
	if morto or int(inventario.get(item, 0)) <= 0:
		return false
	if dados.has("dano") or dados.has("defesa"):
		equipar(item)
		return true
	var cura := int(dados.get("cura", 0))
	var mata_fome := float(dados.get("fome", 0))
	if (cura <= 0 and mata_fome <= 0.0) or (vida >= vida_max and fome >= 99.0) or _comendo > 0.0:
		return false
	vida = mini(vida_max, vida + cura)
	vida_mudou.emit(vida, vida_max)
	fome = minf(100.0, fome + mata_fome)
	fome_mudou.emit(fome)
	inventario[item] = int(inventario[item]) - 1
	if int(inventario[item]) <= 0:
		inventario.erase(item)
	inventario_mudou.emit(inventario)
	if montaria == null:   # comer leva um instante: o Torin fica parado fazendo o gesto
		_comendo = 1.1
		_travou_para_comer = not travado
		travado = true
		animacao_atual = "Interact"
		visual.tocar("Interact", 0.1)
	get_tree().call_group("sons", "tocar", "comer")
	return true


## Põe na mão a arma (muda o dano do golpe) ou veste a armadura (muda a defesa). Equipar de novo a armadura que já está
## vestida tira. O item continua na bolsa.
func equipar(item: String) -> void:
	var dados: Dictionary = Itens.DADOS.get(item, {})
	if dados.has("dano"):
		equipado["arma"] = item
		dano_golpe = int(dados["dano"])
		var a: Dictionary = dados["arma"]
		visual.trocar_arma(load(String(dados["modelo"])), float(a["escala"]), a["giro"], a["deslocamento"], a["empunhadura"])
	elif dados.has("defesa"):
		if equipado["armadura"] == item:
			equipado["armadura"] = ""
			defesa = 0.0
			visual.vestir({})
		else:
			equipado["armadura"] = item
			defesa = float(dados["defesa"])
			visual.vestir(dados["veste"])
	equipamento_mudou.emit(equipado)


func reviver() -> void:
	vida = vida_max
	morto = false
	_golpeando = false
	_rolando = false
	_invulneravel = 1.5
	animacao_atual = ""
	vida_mudou.emit(vida, vida_max)


func _ler_entrada() -> Vector2:
	if entrada_forcada != Vector2.ZERO:
		return entrada_forcada.limit_length(1.0)
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		v.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		v.x += 1.0
	return v.limit_length(1.0)


## Sobe na montaria: o cavaleiro salta do chão até o assento (Sitting_Enter) e só então o controle passa para a montaria.
## Corpo da montaria que colide enquanto se cavalga: uma caixa do tamanho do bicho (o corpo do cavalo desliga a própria colisão ao ser
## montado, e a cápsula do Torin é fina; sem esta caixa o cavalo atravessava pedra e parede). Montaria que voa não ganha caixa.
var _forma_montaria: CollisionShape3D


func _criar_forma_montaria(m: Montaria) -> void:
	_remover_forma_montaria()
	if m.voa:
		return
	var caixa := Solidos.caixa_de(m.dono, 0.85)   # no espaço do dono (o dono gira PI em relação ao corpo do jogador)
	if caixa.size.length() < 0.5:
		return
	_forma_montaria = CollisionShape3D.new()
	_forma_montaria.name = "FormaDaMontaria"
	var bx := BoxShape3D.new()
	bx.size = Vector3(caixa.size.x, caixa.size.y, caixa.size.z)
	_forma_montaria.shape = bx
	var c := caixa.get_center()
	_forma_montaria.position = Vector3(-c.x, c.y - (m.dono.global_position.y - global_position.y), -c.z)   # o dono está virado PI: x e z invertem
	add_child(_forma_montaria)


func _remover_forma_montaria() -> void:
	if _forma_montaria and is_instance_valid(_forma_montaria):
		_forma_montaria.queue_free()
	_forma_montaria = null


func montar(m: Montaria) -> void:
	montaria = m
	m.montada = true
	_criar_forma_montaria(m)
	_voando = false
	_golpeando = false
	_rolando = false
	velocity = Vector3.ZERO
	_transicao = DURACAO_MONTAR
	_inicio_montar = visual.global_position
	animacao_atual = "Sitting_Enter"
	visual.tocar("Sitting_Enter", 0.1)
	if camera:
		_camera_antes = Vector2(camera.altura_do_foco, camera.distancia)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(camera, "altura_do_foco", m.camera_altura, 0.8)
		tw.tween_property(camera, "distancia", m.camera_distancia, 0.8)
		tw.tween_property(camera.braco, "spring_length", m.camera_distancia, 0.8)


## Está a até `distancia` metros do chão? (pouso numa ladeira não conta como `is_on_floor`, mas dá para desmontar.)
func perto_do_chao(distancia := 1.5) -> bool:
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3(0.0, 0.3, 0.0), global_position + Vector3(0.0, -distancia, 0.0), 1)
	q.exclude = [get_rid()]
	return not get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## Desce ao lado da criatura (no chão): o cavaleiro salta do assento (Sitting_Exit) até o chão.
func desmontar() -> void:
	if montaria == null:
		return
	var m := montaria
	_remover_forma_montaria()
	var assento := visual.global_position
	montaria = null
	m.montada = false
	_voando = false
	_transicao = 0.0
	var lado := global_transform.basis.x
	global_position = m.dono.global_position + lado * (4.5 if m.voa else 2.2)
	velocity = Vector3.ZERO
	visual.global_position = assento
	_saindo = DURACAO_DESMONTAR
	animacao_atual = "Sitting_Exit"
	visual.tocar("Sitting_Exit", 0.1)
	var de := visual.position   # posição local do assento, medida depois de mover o corpo
	var tw2 := create_tween()
	tw2.tween_method(func(t: float) -> void:
		visual.position = de.lerp(Vector3.ZERO, t) + Vector3(0.0, sin(t * PI) * 0.5, 0.0), 0.0, 1.0, DURACAO_DESMONTAR)
	tw2.tween_callback(func() -> void: visual.position = Vector3.ZERO)
	if camera:
		var tw3 := create_tween().set_parallel(true)
		tw3.tween_property(camera, "altura_do_foco", _camera_antes.x, 0.8)
		tw3.tween_property(camera, "distancia", _camera_antes.y, 0.8)
		tw3.tween_property(camera.braco, "spring_length", _camera_antes.y, 0.8)


## Movimento montado: WASD relativo à câmera, Shift acelera. Montaria voadora: Espaço sobe, C desce.
func _mover_montado(delta: float) -> void:
	var m := montaria
	if _transicao > 0.0:   # subindo: o cavaleiro salta do chão ao assento; a montaria espera parada
		_transicao -= delta
		var t := clampf(1.0 - _transicao / DURACAO_MONTAR, 0.0, 1.0)
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y = 0.0 if is_on_floor() else velocity.y - gravidade * delta
		move_and_slide()
		m.tocar("Idle")
		m.posicionar(global_position, rotation.y)
		var assento := m.assento_global() - Vector3(0.0, QUADRIL_SENTADO, 0.0)
		visual.global_position = _inicio_montar.lerp(assento, t * t * (3.0 - 2.0 * t)) + Vector3(0.0, sin(t * PI) * 0.6, 0.0)
		return
	var entrada := Vector2.ZERO
	var rapido := false
	var vertical := 0.0
	if not travado and not morto:
		entrada = _ler_entrada()
		rapido = correndo_forcado or Input.is_physical_key_pressed(KEY_SHIFT)
		if m.voa:
			if Input.is_physical_key_pressed(KEY_SPACE):
				vertical += 1.0
			if Input.is_physical_key_pressed(KEY_C):
				vertical -= 1.0
	var yaw := camera.yaw if camera else 0.0
	var dir := Vector3(entrada.x, 0.0, entrada.y).rotated(Vector3.UP, yaw)
	if m.voa:
		if vertical > 0.0:
			_voando = true
		elif _voando and vertical < 0.0 and is_on_floor():
			_voando = false
	if m.voa and _voando:
		var vh := m.velocidade_voo_rapido if rapido else m.velocidade_voo
		velocity = Vector3(dir.x * vh, vertical * m.velocidade_vertical, dir.z * vh)
	else:
		var vt := m.velocidade_correndo if rapido else m.velocidade_andando
		velocity.x = dir.x * vt
		velocity.z = dir.z * vt
		if is_on_floor():
			velocity.y = m.forca_pulo if (_pulo_pedido and m.forca_pulo > 0.0) else 0.0
		else:
			velocity.y -= gravidade * delta
	_pulo_pedido = false
	move_and_slide()
	if dir.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), giro * 0.6 * delta)
	var animacao := "Idle"
	var ritmo := 1.0
	if m.voa and _voando:
		animacao = "Fly"
	elif not is_on_floor() and m.forca_pulo > 0.0:
		animacao = "Jump"
	elif dir.length() > 0.01:
		animacao = "Run" if rapido else m.anim_andando
		ritmo = m.ritmo_correndo if rapido else m.ritmo_andando
	m.tocar(animacao, ritmo)
	m.posicionar(global_position, rotation.y)
	visual.global_position = m.assento_global() - Vector3(0.0, QUADRIL_SENTADO, 0.0)
	if _reacao <= 0.0 and animacao_atual != "Sitting_Idle":
		animacao_atual = "Sitting_Idle"
		visual.tocar("Sitting_Idle", 0.2)
