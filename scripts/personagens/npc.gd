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
@export var oferece_missao := ""      # id da missão que este NPC passa na primeira conversa
@export var segue_jogador := false   # criança curiosa: acompanha o jogador à distância

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
var _comentario := 6.0
var _marca: Label3D       # "!" (oferece missão) ou "?" (a missão ativa pede para falar ou entregar a ele)
var _t_marca := 0.0
var pernoita := true      # vai para casa à noite e quando chove (guardas e vigias continuam no posto)
var casa := Vector3.INF   # ponto diante da porta da casa mais perto (coordenadas do pai)
var _recolhido := false
var _t_horario := 0.0
var _medo := false          # um monstro caça por perto: corre para dentro da casa mais perto
var _t_sem_ameaca := 0.0
var _dentro_de_casa := false
var _ameaca_pos := Vector3.INF   # onde está o monstro que assusta (para fugir na direção contrária)
var _cama: Cama = null     # a cama em que dorme
var _casa_no: Node3D = null
var _deitado := false
var _entrando_na_casa := false   # caminhando da porta até a cama
var _anim_descanso := ""
var _melhor_dist := 1e9   # progresso rumo à casa (para detectar quem empacou)
var _t_sem_progresso := 0.0
var _t_desvio := 0.0
var _dir_desvio := Vector3.ZERO
var _trilha := PackedVector3Array()   # caminho de verdade até casa, pela malha de navegação
var _i_trilha := 0
var _recalculos := 0
var _pausas := 0          # > 0: conversando ou levando um golpe; a rotina espera


func _ready() -> void:
	visual = cena.instantiate()
	visual.animacao_inicial = animacao
	visual.rotation_degrees.y = 180.0
	add_child(visual)
	name = nome if nome != "" else name
	add_to_group("atingiveis")
	add_to_group("npcs")
	corpo = Solidos.corpo_movel(self, AABB(Vector3(-0.35, 0.0, -0.35), Vector3(0.7, 1.8, 0.7)))   # o jogador não atravessa as pessoas
	if not rotina.is_empty():
		_proximo_passo()
	_marca = Label3D.new()
	_marca.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_marca.font_size = 120
	_marca.pixel_size = 0.006
	_marca.outline_size = 16
	_marca.modulate = Color(1.0, 0.82, 0.2)
	_marca.position = Vector3(0.0, 2.55, 0.0)
	_marca.visible = false
	add_child(_marca)


## Marcador de missão sobre a cabeça: "?" se a missão ativa pede para falar com ele ou entregar algo; "!" se ele passa uma missão.
func _process(delta: float) -> void:
	_t_marca -= delta
	if _t_marca <= 0.0:
		_t_marca = 0.4
		_marca.text = _qual_marca()
		_marca.visible = _marca.text != ""
	if _marca.visible:
		_marca.position.y = 2.55 + sin(Time.get_ticks_msec() / 250.0) * 0.07


func _qual_marca() -> String:
	var m := GerenciadorMissoes.instancia
	if m == null or morto or not Jogo.historia:   # sem a história ligada ninguém mostra "!" nem "?"
		return ""
	var meu := nome.to_lower()
	for id in m.ativas:
		for obj in DadosMissoes.MISSOES[id]["objetivos"]:
			if obj["tipo"] in ["falar", "entregar"] and obj["alvo"] == meu and m.feito(id, obj["id"]) < int(obj["qtd"]):
				return "?"
	if oferece_missao != "" and m.pode_iniciar(oferece_missao):
		return "!"
	return ""


## Chamado quando a região do NPC liga (o jogador chegou perto): se já é hora de dormir (ou chove forte), ele já está
## deitado na cama, e se já é dia, já está de pé no trabalho. Sem isso a vila inteira estaria parada nos postos à noite
## e só depois sairia andando para casa à vista do jogador.
func acomodar_ao_horario() -> void:
	if segue_jogador or not pernoita or papel.findn("guarda") >= 0 or papel.findn("vigia") >= 0 or papel.findn("sentinela") >= 0 or papel.findn("preso") >= 0:
		return
	var jogo := get_tree().get_first_node_in_group("jogo")
	var clima: Clima = jogo.get("clima") if jogo else null
	if clima == null:
		return
	var quer := clima.hora_de_dormir() or clima.chuva > 0.4
	if quer and not _recolhido:
		_recolhido = true
		if casa == Vector3.INF:
			casa = _achar_casa()
		if _cama != null:
			_deitar()
	elif not quer and _recolhido:
		_recolhido = false
		_acordar()
		_soltar_reserva()
		_sair_de_casa()
		if not rotina.is_empty():
			_proximo_passo()


## O dia do NPC: trabalha de dia; das 19h30 às 5h30, ou com chuva forte, vai para a porta da casa mais perto e descansa.
## Devolve true quando o horário está no comando (a rotina de trabalho fica parada).
func _horario(delta: float) -> bool:
	_t_horario -= delta
	if _t_horario <= 0.0:
		_t_horario = 0.5 + float(hash(nome) % 100) / 200.0
		if papel.findn("guarda") >= 0 or papel.findn("vigia") >= 0 or papel.findn("sentinela") >= 0 or papel.findn("preso") >= 0:
			pernoita = false
			return false
		if _ameacado():
			_medo = true
			_t_sem_ameaca = 0.0
		else:
			_t_sem_ameaca += 0.7
			if _t_sem_ameaca > 8.0:
				_medo = false
		var jogo := get_tree().get_first_node_in_group("jogo")
		var clima: Clima = jogo.get("clima") if jogo else null
		if clima or _medo:
			var quer := _medo or clima.hora_de_dormir() or clima.chuva > 0.4
			if quer and not _recolhido:
				if papel.findn("guarda") >= 0 or papel.findn("vigia") >= 0 or papel.findn("sentinela") >= 0 or papel.findn("preso") >= 0:
					pernoita = false
					return false
				_recolhido = true
				_melhor_dist = 1e9
				_trilha = PackedVector3Array()
				_recalculos = 0
				if casa == Vector3.INF:
					casa = _achar_casa()
			elif not quer and _recolhido:
				_recolhido = false
				_acordar()
				_soltar_reserva()
				_sair_de_casa()
				_melhor_dist = 1e9
				if not rotina.is_empty():
					_proximo_passo()
	if not _recolhido:
		return false
	if _deitado:
		return true   # dormindo (ou a caminho da cama) até de manhã
	if _pausas > 0:
		return true   # conversando
	var ate := casa - position
	ate.y = 0.0
	if ate.length() > 0.7:
		if _seguir_trilha(delta):
			return true
		var dir := ate.normalized()
		if ate.length() < _melhor_dist - 0.4:
			_melhor_dist = ate.length()
			_t_sem_progresso = 0.0
		else:
			_t_sem_progresso += delta
			if _t_sem_progresso > 3.0 and _t_desvio <= 0.0:   # empacou: anda uns segundos para o lado e tenta de novo
				_t_sem_progresso = 0.0
				_t_desvio = 2.5
				_dir_desvio = dir.rotated(Vector3.UP, randf_range(0.9, 2.2) * (1.0 if randf() < 0.5 else -1.0))
				_melhor_dist = ate.length()
		var livre := _caminho_livre(dir)
		if _t_desvio > 0.0:
			_t_desvio -= delta
			dir = _dir_desvio
			livre = _caminho_livre(dir)
		elif not livre:   # cerca ou casa no caminho: contorna, tentando desvios para os dois lados
			for desvio in [0.7, -0.7, 1.4, -1.4, 2.1, -2.1]:
				var d2 := dir.rotated(Vector3.UP, desvio)
				if _caminho_livre(d2):
					dir = d2
					livre = true
					break
		if livre:
			position += dir * 2.4 * delta
			rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 6.0 * delta)
			visual.tocar("Jog_Fwd" if ate.length() > 30.0 else "Walk", 0.2)
			if altura_em.is_valid():
				position.y = altura_em.call(position.x, position.z)
		else:
			visual.tocar("Idle", 0.2)
	elif _medo:
		_entrar_em_casa()   # chegou à porta com o monstro por perto: entra e se esconde
	elif _cama != null:
		_deitar()           # hora de dormir: entra e deita na cama
	else:
		visual.tocar("Idle", 0.4)   # sem cama livre por perto: espera de pé na porta, nunca sentado ao relento
	return true


## Anda pelo caminho que a malha de navegação traçou até casa. Devolve false se não há malha (aí vale a linha reta com desvios).
func _seguir_trilha(delta: float) -> bool:
	var mapa := get_world_3d().navigation_map
	var pai := get_parent() as Node3D
	var destino := pai.to_global(casa) if pai else casa
	if _trilha.is_empty() and _recalculos < 3:
		_recalculos += 1
		_trilha = NavigationServer3D.map_get_path(mapa, global_position, destino, true)
		_i_trilha = 1
	if _trilha.size() < 2:
		return false
	if _i_trilha >= _trilha.size():
		_trilha = PackedVector3Array()   # chegou ao fim da trilha: se ainda não está na porta, recalcula (até 3 vezes)
		return _recalculos < 3 and (destino - global_position).length() > 1.5
	var alvo := _trilha[_i_trilha]
	var d := alvo - global_position
	d.y = 0.0
	if d.length() < 0.6:
		_i_trilha += 1
		return true
	var dir := d.normalized()
	position += dir * (4.4 if _medo else 2.4) * delta
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 6.0 * delta)
	visual.tocar("Sprint" if _medo and visual.tem("Sprint") else ("Jog_Fwd" if (destino - global_position).length() > 30.0 else "Walk"), 0.2)
	if altura_em.is_valid():
		position.y = altura_em.call(position.x, position.z)
	return true


## Ponto diante da porta da casa mais perto que tem cama livre (até 200 m); sem casa por perto, fica onde está.
func _achar_casa() -> Vector3:
	var melhor: Node3D = null
	var dmin := 200.0
	for c: Node3D in get_tree().get_nodes_in_group("casas"):
		var d := c.global_position.distance_to(global_position)
		if _ameaca_pos != Vector3.INF:   # fugindo: casa na direção do monstro conta como mais longe (não corre para cima dele)
			var para_casa := (c.global_position - global_position).normalized()
			var para_monstro := (_ameaca_pos - global_position).normalized()
			if para_casa.dot(para_monstro) > 0.4:
				d += 45.0
		if d < dmin and c.has_meta("x_porta") and _cama_livre(c) != null:
			dmin = d
			melhor = c
	if melhor == null:
		return position
	_casa_no = melhor
	_cama = _cama_livre(melhor)
	_cama.dono = nome
	var porta := melhor.to_global(Vector3(float(melhor.get_meta("x_porta")), 0.0, float(melhor.get_meta("linhas")) + 1.8))
	var pai := get_parent() as Node3D
	var local := pai.to_local(porta) if pai else porta
	var folga := float(hash(nome) % 100) / 100.0 * 2.4 - 1.2   # cada um fica num lugar da soleira
	local += Vector3(folga, 0.0, 0.0).rotated(Vector3.UP, melhor.global_rotation.y)
	return local


func _cama_livre(c: Node3D) -> Cama:
	for d in c.get_meta("camas", []):
		var cm := d["no"] as Cama
		if cm != null and (cm.dono == "" or cm.dono == nome):
			return cm
	return null


## Passou o susto de dia: solta a cama reservada ao escolher o abrigo (senão as camas ficavam presas a quem nem dorme lá).
func _soltar_reserva() -> void:
	if _cama and not _deitado:
		_cama.dono = ""
		_cama = null
		casa = Vector3.INF


## Chegou à porta e é hora de dormir: entra, vai até a cama e deita (a casa esconde o NPC por fora).
## Entra pela porta, anda até a cama e deita. Se o jogador não está olhando (a mais de 40 m), deita direto, sem a caminhada.
func _deitar() -> void:
	if _deitado or _cama == null or _casa_no == null:
		return
	_deitado = true
	var dados: Dictionary = {}
	for d in _casa_no.get_meta("camas", []):
		if d["no"] == _cama:
			dados = d
	var cama_global: Vector3 = _casa_no.to_global(dados["pos"] as Vector3)
	var porta_dentro: Vector3 = _casa_no.to_global(Vector3(float(_casa_no.get_meta("x_porta")), 0.0, float(_casa_no.get_meta("linhas")) - 1.0))
	var pai := get_parent() as Node3D
	var jogador := get_tree().get_first_node_in_group("jogador") as Node3D
	var perto := jogador != null and jogador.global_position.distance_to(global_position) < 40.0
	if not perto:
		_ao_chegar_na_cama(dados, cama_global, pai)
		return
	var pontos: Array[Vector3] = [Vector3(global_position.x, 0.0, global_position.z), porta_dentro, Vector3(cama_global.x, 0.0, cama_global.z)]
	var tw := create_tween()
	_entrando_na_casa = true
	visual.tocar("Walk", 0.2)
	var atual := global_position
	for p in pontos.slice(1):
		var dest := Vector3(p.x, global_position.y if p != pontos[2] else cama_global.y, p.z)
		var dur := maxf(0.3, atual.distance_to(dest) / 1.6)
		tw.tween_callback(func() -> void:
			var d: Vector3 = dest - global_position
			if d.length() > 0.05:
				rotation.y = atan2(-d.x, -d.z))
		tw.tween_property(self, "global_position", dest, dur)
		atual = dest
	tw.tween_callback(func() -> void:
		_entrando_na_casa = false
		_ao_chegar_na_cama(dados, cama_global, pai))


func _ao_chegar_na_cama(dados: Dictionary, cama_global: Vector3, pai: Node3D) -> void:
	position = pai.to_local(cama_global) if pai else cama_global
	position.y += 0.05
	visual.tocar("Death01", 0.1)
	if visual.animacoes:
		var a := visual.animacoes.get_animation("Death01")
		visual.animacoes.seek(a.length, true)
		visual.animacoes.pause()
	_alinhar_na_cama(dados)


## Gira o corpo deitado até a cabeça ficar do lado do travesseiro e o corpo na direção comprida da cama
## (mede o osso da cabeça em relação ao quadril na pose final, em vez de supor para onde a animação aponta).
func _alinhar_na_cama(dados: Dictionary) -> void:
	await get_tree().process_frame
	var esq: Skeleton3D = visual.find_child("Skeleton3D", true, false)
	if esq == null:
		return
	var cab := esq.find_bone("neck_01")
	var bac := esq.find_bone("pelvis")
	if cab < 0 or bac < 0:
		return
	var corpo_dir: Vector3 = esq.global_transform * esq.get_bone_global_pose(cab).origin - esq.global_transform * esq.get_bone_global_pose(bac).origin
	corpo_dir.y = 0.0
	var alvo: Vector3 = _casa_no.global_transform.basis * (dados["cabeceira"] as Vector3)
	alvo.y = 0.0
	if corpo_dir.length() < 0.05 or alvo.length() < 0.05:
		return
	rotation.y += atan2(alvo.x, alvo.z) - atan2(corpo_dir.x, corpo_dir.z)
	await get_tree().process_frame
	var dep: Vector3 = esq.global_transform * esq.get_bone_global_pose(cab).origin - esq.global_transform * esq.get_bone_global_pose(bac).origin
	dep.y = 0.0
	if dep.length() > 0.01 and dep.normalized().dot(alvo.normalized()) < 0.5:   # ficou de cabeça para o pé da cama: vira meia-volta
		rotation.y += PI
		await get_tree().process_frame
	# centraliza o tronco sobre o centro da cama
	var meio: Vector3 = (esq.global_transform * esq.get_bone_global_pose(cab).origin + esq.global_transform * esq.get_bone_global_pose(bac).origin) / 2.0
	var cama_centro: Vector3 = _casa_no.to_global(dados["pos"] as Vector3)
	var d := cama_centro - meio
	d.y = 0.0
	global_position += d


func _acordar() -> void:
	if not _deitado:
		return
	_deitado = false
	_entrando_na_casa = false
	if visual.animacoes:
		visual.animacoes.play("Idle")
	if casa != Vector3.INF:
		position = casa
		if altura_em.is_valid():
			position.y = altura_em.call(position.x, position.z)
	if _cama:
		_cama.dono = ""


## Algum monstro (ou guarda) em perseguição a menos de 28 m? Quem está parado não assusta.
func _ameacado() -> bool:
	_ameaca_pos = Vector3.INF
	for e in get_tree().get_nodes_in_group("inimigos"):
		var ini := e as Inimigo
		if ini == null or ini.estado == Inimigo.Estado.MORTO:
			continue
		var d := ini.global_position.distance_to(global_position)
		var bicho_selvagem := ini.especie in ["lobo", "javali", "urso", "cao_guerra"]
		if (ini.estado != Inimigo.Estado.PARADO and d < 28.0) or (bicho_selvagem and d < 16.0):   # um lobo parado mas perto também assusta
			_ameaca_pos = ini.global_position
			return true
	return false


func _entrar_em_casa() -> void:
	if _dentro_de_casa:
		return
	_dentro_de_casa = true
	visible = false
	corpo.collision_layer = 0
	remove_from_group("npcs")
	remove_from_group("atingiveis")


func _sair_de_casa() -> void:
	if not _dentro_de_casa:
		return
	_dentro_de_casa = false
	visible = true
	corpo.collision_layer = Solidos.CAMADA_SERES
	add_to_group("npcs")
	add_to_group("atingiveis")


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
	if not segue_jogador and pernoita and _horario(delta):
		return
	if segue_jogador and _pausas == 0:
		_seguir(delta)
		return
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
	var destino: Vector3 = p["ir"]   # as rotinas são escritas nas coordenadas do pai (a área ou o mundo)
	var ate := destino - position
	ate.y = 0.0
	if ate.length() < 0.25:
		_proximo_passo()
		return
	var dir := ate.normalized()
	if _caminho_livre(dir):
		_preso = 0.0
		position += dir * float(p.get("vel", 1.5)) * delta
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 6.0 * delta)
		visual.tocar(String(p.get("anim", "Walk")), 0.2)
		if altura_em.is_valid():
			position.y = altura_em.call(position.x, position.z)
	else:   # alguém no caminho (o jogador, um animal): espera um pouco e, se não sair, pula este passo
		_preso += delta
		visual.tocar("Idle", 0.2)
		if _preso > 3.0:
			_preso = 0.0
			_proximo_passo()


## Segue o jogador: anda até ficar a ~4 m (correndo se estiver longe), olha para ele quando parado e comenta o Fagulha.
func _seguir(delta: float) -> void:
	var jog := get_tree().get_first_node_in_group("jogador") as Node3D
	if jog == null:
		return
	var ate := jog.global_position - global_position
	ate.y = 0.0
	if ate.length() > 4.5:
		var dir := ate.normalized()
		if _caminho_livre(dir):
			var rapido := ate.length() > 10.0
			global_position += dir * (3.6 if rapido else 1.9) * delta
			rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 6.0 * delta)
			visual.tocar("Jog_Fwd" if rapido else "Walk", 0.2)
		else:
			visual.tocar("Idle", 0.2)
		if altura_em.is_valid():
			position.y = altura_em.call(position.x, position.z)
	else:
		visual.tocar("Idle", 0.2)
		rotation.y = lerp_angle(rotation.y, atan2(-ate.x, -ate.z), 4.0 * delta)
		_comentario -= delta
		if _comentario <= 0.0:
			_comentario = 14.0
			for no in get_tree().get_nodes_in_group("montarias"):
				var m := no as Montaria
				if m and m.nome == "Fagulha" and m.dono.global_position.distance_to(global_position) < 14.0:
					_falar_solto(["Ele cospe fogo de verdade?", "Posso fazer carinho no dragão?", "Ele é enorme!"][randi() % 3])
					break


func _falar_solto(texto: String) -> void:
	if _protesto == null:
		_protesto = Label3D.new()
		_protesto.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_protesto.position = Vector3(0.0, 2.3, 0.0)
		_protesto.font_size = 48
		_protesto.pixel_size = 0.006
		_protesto.outline_size = 12
		_protesto.no_depth_test = true
		add_child(_protesto)
	_protesto.text = texto
	_protesto.visible = true
	get_tree().create_timer(3.0).timeout.connect(func() -> void: _protesto.visible = false)


## Raios à frente contra o mundo e outros seres (camadas 1 e 8), partindo da altura do peito.
func _caminho_livre(dir: Vector3) -> bool:
	return Solidos.caminho_livre(self, global_position + Vector3(0.0, 0.9, 0.0), dir, 0.7, 0.35, [corpo.get_rid()])


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
		var alvo_olhar: Vector3 = p["olhar"]
		var pai := get_parent() as Node3D
		olhar_para(pai.to_global(alvo_olhar) if pai else alvo_olhar)
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
