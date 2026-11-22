extends SceneTree
# O jogador anda de frente contra cada coisa sólida do Refúgio e tem que ficar do lado de cá dela:
# animais (parados), as 6 pessoas, o Fagulha, a carroça, os 5 caixotes, a pilha de lenha, uma pedra da fogueira, a cerca.
# Também confere que a abertura da fogueira deixa chegar ao fogo e que o cavalo montado não prende o jogador.
#   godot --path . --resolution 1280x720 --script res://tools/teste_solidos.gd
var jogo: Jogo
var jog: Jogador
var checks := {}


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	jog = jogo.get_node("Jogador")
	_rodar.call_deferred()


func esperar(s: float) -> void:
	await create_timer(s).timeout


func marcar(nome: String, ok: bool, detalhe := "") -> void:
	checks[nome] = ok
	print("  ", "PASSOU " if ok else "FALHOU ", nome, ("  [" + detalhe + "]") if detalhe != "" else "")


## Caminha de frente contra `alvo` a partir de 4 m (do lado do centro da clareira) por 2,2 s (~9 m) e devolve a MENOR
## distância horizontal entre o jogador e o centro do alvo durante a caminhada. A cápsula do jogador tem 0,35 m de
## raio: com o alvo sólido a distância nunca cai de ~0,4 m (ele desliza pela lateral); atravessando, chega perto de 0.
func empurrar_contra(alvo: Vector3) -> float:
	var h := jogo.area
	var pre := PhysicsPointQueryParameters3D.new()
	pre.position = alvo + Vector3(0, 0.45, 0)
	pre.collision_mask = Solidos.CAMADA_SERES | 1
	var antes := h.get_world_3d().direct_space_state.intersect_point(pre, 4).size()
	if antes == 0:
		print("    PRE alvo ", alvo.snapped(Vector3(0.1, 0.1, 0.1)), ": nenhum corpo sólido no ponto do alvo")
	var para_dentro := (Vector3(0, 0, 0) - alvo)
	para_dentro.y = 0.0
	var dir := (para_dentro.normalized() if para_dentro.length() > 1.0 else Vector3(1, 0, 0)) * -1.0   # caminha para longe do centro
	var ini := alvo - dir * 4.0
	jog.global_position = Vector3(ini.x, h.altura_em(ini.x, ini.z) + 0.3, ini.z)
	jog.velocity = Vector3.ZERO
	jogo.camera.yaw = atan2(-dir.x, -dir.z)
	jog.rotation.y = jogo.camera.yaw
	await esperar(0.35)
	jog.entrada_forcada = Vector2(0, -1)
	var minima := 99.0
	var onde := Vector3.ZERO
	var t := 0.0
	while t < 2.2:
		await physics_frame
		t += 1.0 / 60.0
		var rel := jog.global_position - alvo
		if Vector2(rel.x, rel.z).length() < minima:
			minima = Vector2(rel.x, rel.z).length()
			onde = jog.global_position
	jog.entrada_forcada = Vector2.ZERO
	if minima < 0.38:
		print("    DIAG alvo=", alvo.snapped(Vector3(0.1, 0.1, 0.1)), " inicio=", ini.snapped(Vector3(0.1, 0.1, 0.1)), " ponto_mais_perto=", onde.snapped(Vector3(0.1, 0.1, 0.1)), " yaw=", snapped(jogo.camera.yaw, 0.01))
		var q := PhysicsPointQueryParameters3D.new()
		q.position = onde + Vector3(0, 0.9, 0)
		q.collision_mask = 1 | 4 | 8
		for r in jogo.area.get_world_3d().direct_space_state.intersect_point(q, 4):
			print("    DIAG dentro de: ", r.collider.get_path() if r.collider else "?", " layer=", (r.collider as CollisionObject3D).collision_layer)
	return minima


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await esperar(0.2)
	await esperar(1.5)
	var area := jogo.area
	for a in area.find_children("*", "AnimalVila", false, false):
		(a as AnimalVila).set_physics_process(false)   # congela o passeio: o teste mede só a colisão
		(a as AnimalVila).corpo.collision_layer = Solidos.CAMADA_SERES
	jogo.fagulha.set_physics_process(false)

	print("== ANIMAIS ==")
	for a in area.find_children("*", "AnimalVila", false, false):
		var cs0: CollisionShape3D = a.corpo.get_child(0)
		print("    ESTADO ", a.name, " especie=", a.especie, " layer_corpo=", a.corpo.collision_layer, " corpo_vs_animal=", snapped(a.corpo.global_position.distance_to(a.global_position), 0.01), " forma_desativada=", cs0.disabled, " morto=", a.morto, " montada=", a.montaria.montada if a.montaria else false, " processando_fisica=", a.is_physics_processing(), " | fisica_vs_no=", snapped((PhysicsServer3D.body_get_state(a.corpo.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM) as Transform3D).origin.distance_to(a.corpo.global_position), 0.01), " sync=", a.corpo.sync_to_physics)
		var p := await empurrar_contra(a.global_position)
		marcar("Não atravessa %s (%s)" % [a.nome, a.name], p >= 0.38, "menor distância %.2f m" % p)
	print("== PESSOAS ==")
	for n in area.npcs:
		var p := await empurrar_contra(n.global_position)
		marcar("Não atravessa %s" % n.nome, p >= 0.38, "menor distância %.2f m" % p)
	print("== FAGULHA ==")
	jogo.fagulha.global_position = Vector3(12.0, area.altura_em(12.0, 14.0), 14.0)
	await esperar(0.4)
	var pf := await empurrar_contra(jogo.fagulha.global_position)
	marcar("Não atravessa o Fagulha", pf >= 0.38, "menor distância %.2f m" % pf)
	print("== CENÁRIO ==")
	for pr in get_nodes_in_group("props_solidos"):
		var p := await empurrar_contra(pr.global_position)
		marcar("Não atravessa %s em %s" % [pr.name, pr.global_position.snapped(Vector3(0.1, 0.1, 0.1))], p >= 0.38, "menor distância %.2f m" % p)
	var lenha := Vector3(20.3, 0.0, -26.0)
	var pl := await empurrar_contra(lenha)
	marcar("Não atravessa a pilha de lenha", pl >= 0.38, "menor distância %.2f m" % pl)
	var pedra := Vector3(cos(TAU * 3.0 / 8.0) * 1.1, 0.0, sin(TAU * 3.0 / 8.0) * 1.1)
	var pp := await empurrar_contra(pedra)
	marcar("Não atravessa a pedra 3 da fogueira", pp >= 0.38, "menor distância %.2f m" % pp)
	# a abertura da fogueira (pedra 0, em x=+1,1): vindo de fora pelo +X chega ao fogo
	jog.global_position = Vector3(4.0, area.altura_em(4.0, 0.0) + 0.3, 0.0)
	jog.velocity = Vector3.ZERO
	jogo.camera.yaw = atan2(1.0, 0.0)   # olhando para -X
	jog.rotation.y = jogo.camera.yaw
	await esperar(0.3)
	jog.vida = jog.vida_max
	jog.entrada_forcada = Vector2(0, -1)
	await esperar(1.3)
	jog.entrada_forcada = Vector2.ZERO
	marcar("Pela abertura da fogueira dá para chegar ao fogo", Vector2(jog.global_position.x, jog.global_position.z).length() < 1.2, "a %.2f m do centro" % Vector2(jog.global_position.x, jog.global_position.z).length())
	await esperar(1.0)
	marcar("... e queima", jog.vida < jog.vida_max, "vida %d" % jog.vida)
	print("== CERCA ==")
	jog.global_position = Vector3(-37.0, area.altura_em(-37.0, 5.0) + 0.3, 5.0)
	jog.velocity = Vector3.ZERO
	jogo.camera.yaw = atan2(1.0, 0.0)
	jog.rotation.y = jogo.camera.yaw
	await esperar(0.3)
	jog.entrada_forcada = Vector2(0, -1)
	await esperar(1.6)
	jog.entrada_forcada = Vector2.ZERO
	marcar("Não atravessa a cerca (oeste)", jog.global_position.x > -40.4, "x=%.1f" % jog.global_position.x)

	print("== CAVALO MONTADO ==")
	for a in area.find_children("*", "AnimalVila", false, false):
		(a as AnimalVila).set_physics_process(true)
	var cavalo: AnimalVila = null
	for a in area.find_children("*", "AnimalVila", false, false):
		if a.especie == "cavalo":
			cavalo = a
			break
	jog.global_position = cavalo.global_position + Vector3(2.2, 0.3, 0)
	await esperar(0.5)
	jogo.interagir()
	await esperar(1.4)
	marcar("Montou o cavalo (o corpo dele não prende o cavaleiro)", jog.montaria != null and cavalo.corpo.collision_layer == 0)
	var q0 := jog.global_position
	jog.entrada_forcada = Vector2(0, -1)
	jogo.camera.yaw = atan2(-(Vector3.ZERO - jog.global_position).x, -(Vector3.ZERO - jog.global_position).z)
	await esperar(1.0)
	jog.entrada_forcada = Vector2.ZERO
	marcar("Cavalgou normalmente", jog.global_position.distance_to(q0) > 4.0, "%.1f m" % jog.global_position.distance_to(q0))
	jogo.interagir()
	await esperar(1.2)
	marcar("Desmontou e o cavalo voltou a ser sólido", jog.montaria == null and cavalo.corpo.collision_layer == Solidos.CAMADA_SERES)

	var falhas := 0
	for k in checks:
		if not checks[k]:
			falhas += 1
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
