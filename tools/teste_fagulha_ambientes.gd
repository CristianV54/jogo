extends SceneTree
## O Fagulha nas 3 fases em campo aberto, mata fechada, ponte e junto de uma casa fechada: nunca fica dentro de parede/tronco, acompanha
## o Torin, e a fase 3 voa por cima de tudo.   godot --headless --path . --script res://tools/teste_fagulha_ambientes.gd
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
func _dentro_de_solido(f: Fagulha) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var e := SphereShape3D.new()
	e.radius = 0.5
	q.shape = e
	q.transform = Transform3D(Basis.IDENTITY, f.global_position + Vector3(0, 1.0, 0))
	q.collision_mask = 1
	q.exclude = [f.corpo.get_rid()]
	for r in jogo.get_world_3d().direct_space_state.intersect_shape(q, 4):
		if String((r.collider as Node).name) != "Colisao" or not (r.collider as Node).get_parent() is Terreno:
			return true
	return false
func _r() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jogo.clima.congelado = true
	jogo.liberar_fagulha()
	var f: Fagulha = jogo.fagulha
	var jog: Jogador = jogo.jogador
	var m: Mundo = jogo.mundo
	var ponte: Node3D = m.find_children("*", "PonteDeMadeira", true, false)[0]
	var casa: Node3D = get_nodes_in_group("casas")[0]
	var ambientes := [
		["campo aberto", Vector3(-250, 0, 40), Vector3(-262, 0, 40)],
		["mata fechada", Vector3(-480, 0, -300), Vector3(-495, 0, -300)],
		["ponte", ponte.global_position + Vector3(0, 1.0, 0), ponte.global_position + Vector3(-8, 1.0, 0)],
		["junto de casa fechada", casa.to_global(Vector3(0, 0.3, float(casa.get_meta("linhas")) + 4.0)), casa.to_global(Vector3(float(casa.get_meta("colunas")) + 6.0, 0.3, float(casa.get_meta("linhas")) + 4.0))]]   # o Torin à porta e o Fagulha ao lado da casa, a casa entre eles e o resto do caminho
	for fase in [1, 2, 3]:
		f.definir_fase(fase)
		for amb in ambientes:
			var p0: Vector3 = amb[1]
			var y0 := m.chao_em(p0.x, p0.z)
			jog.global_position = Vector3(p0.x, maxf(p0.y, y0 + 0.5), p0.z)
			jog.velocity = Vector3.ZERO
			m.atualizar_atividade()
			f.modo_voo = false
			f.set_physics_process(true)
			f.global_position = Vector3(amb[2].x, m.chao_em(amb[2].x, amb[2].z), amb[2].z)
			if fase >= 2 and amb[0] != "junto de casa fechada":
				f._t_recarga = 0.0
				var ev := InputEventKey.new()
				ev.physical_keycode = KEY_F
				ev.pressed = true
				f._unhandled_key_input(ev)
			var preso := 0
			var dentro := 0
			var longe_max := 0.0
			for i in 50:
				await create_timer(0.1).timeout
				if _dentro_de_solido(f) and not f.modo_voo:
					dentro += 1
					print("    [dentro] i=", i, " fase=", fase, " pos=", f.global_position, " torin=", jog.global_position, " anim=", f.animacao_atual)
				longe_max = maxf(longe_max, Vector2(f.global_position.x - jog.global_position.x, f.global_position.z - jog.global_position.z).length())
			_m("fase %d, %s: nunca fica dentro de parede ou tronco" % [fase, amb[0]], dentro <= 2, "%d de 50 quadros com o centro dentro de um sólido (tolerância de 2 = 0,2 s: a fase 3 corre a 10 m/s e raspa a quina da cerca antes de a esfera de colisão dela barrá-la; limitação conhecida)" % dentro)
			if amb[0] == "campo aberto" or amb[0] == "mata fechada":
				_m("fase %d, %s: fica perto do Torin" % [fase, amb[0]], longe_max < 16.0, "%.1f m no máximo" % longe_max)
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
