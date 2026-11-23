extends SceneTree
# NPCs fogem para dentro das casas quando um monstro chega perto, e voltam quando passa o perigo.
#   godot --headless --path . --script res://tools/teste_medo.gd
var jogo: Jogo
var falhas := 0


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _marcar(nome: String, ok: bool, det := "") -> void:
	print("  ", "PASSOU " if ok else "FALHOU ", nome, ("  [" + det + "]") if det != "" else "")
	if not ok:
		falhas += 1


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jogo.clima.congelado = true
	jogo.clima.definir_hora(11.0)
	jogo.clima.forcar_tempo(Clima.Tempo.LIMPO)
	var alvos: Array[Npc] = []
	for n in get_nodes_in_group("npcs"):
		var npc := n as Npc
		if npc and str(npc.nome) in ["Tessa", "Dorn", "Mira"]:
			alvos.append(npc)
	_marcar("achou NPCs civis para o teste", alvos.size() >= 2, str(alvos.size()))
	var lobo := (load("res://scenes/inimigos/lobo.tscn") as PackedScene).instantiate() as Inimigo
	jogo.mundo.add_child(lobo)
	lobo.global_position = alvos[0].global_position + Vector3(10.0, 0.0, 0.0)
	lobo.estado = Inimigo.Estado.PERSEGUINDO
	for i in 100:
		await create_timer(0.1).timeout
		if is_instance_valid(lobo) and lobo.estado == Inimigo.Estado.PARADO:
			lobo.estado = Inimigo.Estado.PERSEGUINDO
	var dentro := 0
	for n in alvos:
		if n._dentro_de_casa:
			dentro += 1
	_marcar("com o lobo solto os NPCs entraram nas casas", dentro >= 1, "%d de %d dentro" % [dentro, alvos.size()])
	_marcar("quem entrou ficou invisível e sem colisão", alvos.filter(func(n: Npc) -> bool: return n._dentro_de_casa and (n.visible or n.corpo.collision_layer != 0)).is_empty())
	lobo.queue_free()
	await create_timer(0.2).timeout
	for i in 300:
		await create_timer(0.1).timeout
		if alvos.all(func(n: Npc) -> bool: return not n._dentro_de_casa):
			break
	var ainda := 0
	for n in alvos:
		if n._dentro_de_casa:
			ainda += 1
	_marcar("sem o lobo eles saem de novo", ainda == 0, "%d ainda dentro" % ainda)
	# lobo PARADO (nunca perseguiu ninguém) perto da vila também assusta, e depois do susto as camas voltam a ficar livres
	var l3 := (load("res://scenes/inimigos/lobo.tscn") as PackedScene).instantiate() as Inimigo
	jogo.mundo.add_child(l3)
	l3.global_position = alvos[1].global_position + Vector3(8.0, 0.0, 0.0)
	l3.set_physics_process(false)   # fica parado
	for i in 80:
		await create_timer(0.1).timeout
	var assustados := 0
	for n in alvos:
		if n._medo or n._dentro_de_casa:
			assustados += 1
	_marcar("lobo parado a menos de 16 m também assusta", assustados >= 1, "%d assustados" % assustados)
	l3.queue_free()
	for i in 200:
		await create_timer(0.1).timeout
		if alvos.all(func(n: Npc) -> bool: return not n._dentro_de_casa and not n._recolhido):
			break
	var camas_presas := 0
	for c in get_nodes_in_group("interagiveis"):
		if c is Cama and (c as Cama).dono != "":
			camas_presas += 1
	_marcar("passado o susto de dia, nenhuma cama fica reservada", camas_presas == 0, "%d camas presas" % camas_presas)
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
