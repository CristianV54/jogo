extends SceneTree
# Testa, na cena principal e com janela: (1) golpe em vaca, ovelha e NPC, (2) montar o cavalo, andar, correr e desmontar,
# (3) montar o Fagulha, decolar, voar, pousar e desmontar.
#   godot --path . --resolution 1280x720 --script res://tools/teste_montaria_dano.gd
# Capturas em tools/capturas/md_*.png

const PASTA := "tools/capturas/"
var jogo: Jogo
var jog: Jogador
var checks := {}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(PASTA)
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	jog = jogo.get_node("Jogador")
	_rodar.call_deferred()


func esperar(s: float) -> void:
	await create_timer(s).timeout


func foto(nome: String) -> void:
	for i in 3:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(PASTA + "md_" + nome + ".png")
	print("FOTO ", nome)


func marcar(nome: String, ok: bool, detalhe := "") -> void:
	checks[nome] = ok
	print("  ", "PASSOU " if ok else "FALHOU ", nome, ("  [" + detalhe + "]") if detalhe != "" else "")


func apertar(tecla: Key, pressionada: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = tecla
	e.keycode = tecla
	e.pressed = pressionada
	Input.parse_input_event(e)


func animal(nome_no: String) -> AnimalVila:
	for a in get_nodes_in_group("atingiveis"):
		if a is AnimalVila and a.name.begins_with(nome_no):
			return a
	return null


func perto_de(alvo: Node3D, dist: float, lado := Vector3(0, 0, 1)) -> void:
	# põe o jogador a `dist` do alvo, olhando para ele
	var p := alvo.global_position + lado.normalized() * dist
	jog.global_position = Vector3(p.x, jogo.area.altura_em(p.x, p.z) + 0.3, p.z)
	var d := alvo.global_position - jog.global_position
	jog.rotation.y = atan2(-d.x, -d.z)
	jogo.camera.yaw = jog.rotation.y
	jog.velocity = Vector3.ZERO


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await esperar(0.2)
	await esperar(2.0)

	# ---------------- dano
	print("== DANO ==")
	var vaca := animal("Vaca")
	var vida0 := vaca.vida
	perto_de(vaca, 1.8)
	await esperar(0.3)
	jog.golpear()
	await esperar(0.62)
	await foto("vaca_golpeada")
	marcar("Vaca perdeu vida ao ser golpeada", vaca.vida < vida0, "%d -> %d" % [vida0, vaca.vida])
	await esperar(1.0)
	var antes := vaca.global_position
	await esperar(1.5)
	marcar("Vaca fugiu depois do golpe", vaca.global_position.distance_to(antes) > 1.0)
	var ovelha := animal("Ovelha")
	perto_de(ovelha, 1.2)
	await esperar(1.6)
	jog.golpear()
	await esperar(0.7)
	await esperar(0.8)
	marcar("Ovelha morreu (22 de dano, 20 de vida)", ovelha.morto, "vida %d" % ovelha.vida)
	marcar("Ovelha tocou Death", ovelha._anim.current_animation == "Death", ovelha._anim.current_animation)
	await foto("ovelha_morta")
	var tessa: Npc = null
	for n in jogo.area.npcs:
		if n.nome == "Tessa":
			tessa = n
	perto_de(tessa, 1.3)
	await esperar(1.6)
	jog.golpear()
	await esperar(0.7)
	await foto("npc_golpeado")
	marcar("NPC protestou (balão de fala visível)", tessa._protesto != null and tessa._protesto.visible, tessa._protesto.text if tessa._protesto else "")
	marcar("NPC continua vivo", not tessa.morto)
	await esperar(2.5)

	# ---------------- cavalo
	print("== CAVALO ==")
	var cavalo := animal("Cavalo")
	perto_de(cavalo, 2.5)
	await esperar(0.6)
	marcar("Há montaria por perto", jogo._montaria_mais_perto() != null)
	jogo.interagir()
	await esperar(0.5)
	marcar("Jogador montou o cavalo", jog.montaria != null and jog.montaria.nome == "Cavalo")
	cavalo = jog.montaria.dono   # há dois cavalos: o montado é o mais perto, não necessariamente o primeiro
	jogo.camera.yaw = jog.rotation.y + 1.3   # câmera de lado, para ver a posição do cavaleiro
	await esperar(0.4)
	await foto("cavalo_lado")
	jogo.camera.yaw = jog.rotation.y
	var rumo := Vector3.ZERO - jog.global_position   # rumo ao centro da clareira, longe de paredes
	jogo.camera.yaw = atan2(-rumo.x, -rumo.z)
	await esperar(0.3)
	var p0 := jog.global_position
	jog.entrada_forcada = Vector2(0, -1)
	jog.correndo_forcado = false
	await esperar(2.0)
	var andou := jog.global_position.distance_to(p0)
	marcar("Cavalo andou ~6 m/s", andou > 8.0 and andou < 14.0, "%.1f m em 2 s" % andou)
	marcar("Cavalo toca Walk", cavalo._anim.current_animation == "Walk", cavalo._anim.current_animation)
	await foto("cavalo_andando")
	jog.correndo_forcado = true
	var p1 := jog.global_position
	await esperar(2.0)
	var correu := jog.global_position.distance_to(p1)
	marcar("Cavalo galopou ~13 m/s", correu > 20.0 and correu < 30.0, "%.1f m em 2 s" % correu)
	marcar("Cavalo toca Run", cavalo._anim.current_animation == "Run", cavalo._anim.current_animation)
	await foto("cavalo_galope")
	var dist_cavalo := cavalo.global_position.distance_to(jog.global_position)
	marcar("Cavalo acompanha o corpo do jogador", dist_cavalo < 0.1, "%.2f m" % dist_cavalo)
	jog.entrada_forcada = Vector2.ZERO
	jog.correndo_forcado = false
	await esperar(0.5)
	jogo.interagir()
	await esperar(0.5)
	marcar("Jogador desmontou", jog.montaria == null)
	marcar("Visual do jogador voltou ao lugar", jog.visual.position.length() < 0.01)

	# ---------------- Fagulha
	print("== FAGULHA ==")
	var fag := jogo.fagulha
	perto_de(fag, 3.5, Vector3(1, 0, 1))
	await esperar(1.0)
	jogo.interagir()
	await esperar(0.5)
	marcar("Jogador montou o Fagulha", jog.montaria != null and jog.montaria.nome == "Fagulha")
	jogo.camera.yaw = jog.rotation.y + 1.3
	await esperar(0.4)
	await foto("fagulha_lado")
	jogo.camera.yaw = jog.rotation.y
	apertar(KEY_SPACE, true)
	await esperar(2.0)
	var y_voo := jog.global_position.y
	marcar("Fagulha decolou (subiu mais de 8 m)", y_voo > 8.0, "y=%.1f" % y_voo)
	marcar("Fagulha toca Fly", fag._anim.current_animation == "Fly", fag._anim.current_animation)
	apertar(KEY_SPACE, false)
	jog.entrada_forcada = Vector2(0, -1)
	var q0 := jog.global_position
	await esperar(2.0)
	var voou := Vector2(jog.global_position.x - q0.x, jog.global_position.z - q0.z).length()
	marcar("Fagulha voou ~16 m/s", voou > 26.0 and voou < 36.0, "%.1f m em 2 s" % voou)
	marcar("Altura se mantém sem apertar nada", absf(jog.global_position.y - y_voo) < 1.0, "y=%.1f" % jog.global_position.y)
	await foto("fagulha_voando")
	jog.entrada_forcada = Vector2.ZERO
	jogo.interagir()
	await esperar(0.3)
	marcar("Não desmonta no ar", jog.montaria != null)
	apertar(KEY_C, true)
	var t := 0.0
	while not jog.is_on_floor() and t < 8.0:
		await esperar(0.2)
		t += 0.2
	await esperar(0.5)
	apertar(KEY_C, false)
	marcar("Fagulha pousou", jog.is_on_floor(), "y=%.1f" % jog.global_position.y)
	await foto("fagulha_pousada")
	jogo.interagir()
	await esperar(0.5)
	marcar("Jogador desmontou do Fagulha", jog.montaria == null)
	await esperar(1.5)
	marcar("Fagulha volta a seguir o jogador", fag._anim.current_animation != "" )

	var falhas := 0
	for k in checks:
		if not checks[k]:
			falhas += 1
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
