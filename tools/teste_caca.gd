extends SceneTree
## O lobo ataca gente e bicho de fazenda de verdade: o NPC é mordido (se encolhe, reclama), foge para casa e volta ao trabalho quando o
## lobo some; o bicho de fazenda perde vida e pode morrer.   godot --headless --path . --script res://tools/teste_caca.gd
var jogo: Jogo
var falhas := 0
func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_r.call_deferred()
func _m(nome: String, ok: bool, det := "") -> void:
	print("  ", "PASSOU " if ok else "FALHOU ", nome, ("  [" + det + "]") if det != "" else "")
	if not ok:
		falhas += 1
func _r() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jogo.clima.congelado = true
	jogo.clima.definir_hora(11.0)
	jogo.clima.forcar_tempo(Clima.Tempo.LIMPO)
	var area := jogo.area
	var jog: Jogador = jogo.jogador
	jog.global_position = Vector3(-60, 6, 120)   # longe: o lobo só vê a vítima
	# --- bicho de fazenda
	var vaca: AnimalVila = null
	for a in area.find_children("*", "AnimalVila", false, false):
		if a.especie == "vaca":
			vaca = a
	for n in area.npcs:
		n.visible = false   # só a vaca é vítima possível neste trecho do teste
	# o lobo ataca o bicho de fazenda MAIS PERTO dele, que pode ser a vaca ou a ovelha vizinha do mesmo curral: vale a vida de todos
	var rebanho: Array[AnimalVila] = []
	for a in area.find_children("*", "AnimalVila", false, false):
		if not (a as AnimalVila).fugitivo and (a as AnimalVila).global_position.distance_to(vaca.global_position) < 14.0:
			rebanho.append(a)
	var vida0 := 0
	for a in rebanho:
		vida0 += a.vida
	var lobo := (load("res://scenes/inimigos/lobo.tscn") as PackedScene).instantiate() as Inimigo
	jogo.mundo.add_child(lobo)
	lobo.global_position = vaca.global_position + Vector3(0.0, 0.3, -2.5)   # dentro do mesmo curral (o lobo não atravessa a cerca)
	for i in 80:
		await create_timer(0.1).timeout
	var vida1 := 0
	var mortos := 0
	for a in rebanho:
		vida1 += a.vida
		mortos += 1 if a.morto else 0
	_m("o lobo ataca um bicho do curral (ele perde vida ou morre)", vida1 < vida0 or mortos > 0, "vida do rebanho %d -> %d, mortos=%d" % [vida0, vida1, mortos])
	lobo.queue_free()
	for n in area.npcs:
		n.visible = true
	for a in area.find_children("*", "AnimalVila", false, false):
		(a as Node3D).visible = false   # agora só o Oren pode ser vítima
	await create_timer(0.3).timeout
	# --- NPC
	var npc: Npc = null
	for n in area.npcs:
		if n.nome == "Oren":
			npc = n
	npc.set_physics_process(false)
	var l2 := (load("res://scenes/inimigos/lobo.tscn") as PackedScene).instantiate() as Inimigo
	jogo.mundo.add_child(l2)
	l2.global_position = npc.global_position + Vector3(-2.5, 0.3, 0.0)
	npc.set_physics_process(true)
	var protestou := false
	var fugiu := false
	for i in 80:
		await create_timer(0.1).timeout
		if npc._protesto != null and npc._protesto.visible:
			protestou = true
		if npc._medo or npc._dentro_de_casa:
			fugiu = true
	_m("o lobo morde o NPC (ele reclama)", protestou)
	_m("o NPC mordido foge para casa", fugiu)
	l2.queue_free()
	for i in 300:
		await create_timer(0.1).timeout
		if not npc._dentro_de_casa and not npc._recolhido and not npc._medo:
			break
	_m("sem o lobo o NPC volta ao trabalho", not npc._dentro_de_casa and not npc._recolhido and not npc._medo and npc.visible)
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
