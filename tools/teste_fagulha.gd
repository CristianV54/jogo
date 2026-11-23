extends SceneTree
## As três fases do Fagulha em jogo real: tamanho e cor, voo, ataque, montaria e a troca de fase pelas missões C1-M4, C2-M3 e C3-M4.
##   godot --headless --path . --script res://tools/teste_fagulha.gd
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
func _tecla_f() -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_F
	ev.pressed = true
	jogo.fagulha._unhandled_key_input(ev)
func _lobo_perto(dist: float) -> Inimigo:
	var l := (load("res://scenes/inimigos/lobo.tscn") as PackedScene).instantiate() as Inimigo
	jogo.mundo.add_child(l)
	l.global_position = jogo.fagulha.global_position + Vector3(dist, 0, 0)
	l.estado = Inimigo.Estado.ATACANDO   # em combate (para a Fagulha reagir)
	l.set_physics_process(false)
	l.vida_max = 500
	l.vida = 500
	return l
func _r() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	var f: Fagulha = jogo.fagulha
	var jog: Jogador = jogo.jogador
	var m: Mundo = jogo.mundo
	jogo.clima.congelado = true
	# antes do resgate: ferida
	_m("antes do resgate a Fagulha é fase 1 e não pode ser montada", f.fase == 1 and not f.montaria.ativa)
	# fase 1
	jogo.missoes.ativas.append("C1-M4")
	jogo.missoes._concluir("C1-M4")
	await create_timer(0.5).timeout
	_m("fase 1: segue o Torin, tamanho 0,7, cinza, não monta", f.fase == 1 and f.alvo == jog and absf(f._modelo.scale.x - 0.7) < 0.01 and not f.montaria.ativa)
	var tinta1: Color = (f._modelo.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).get_surface_override_material(0).albedo_color
	f.global_position = jog.global_position + Vector3(3, 0, 0)
	f.set_physics_process(true)
	_tecla_f()
	await create_timer(0.8).timeout
	_m("fase 1: F não faz voar", not f.modo_voo and f.global_position.y < 0.5 + jog.global_position.y)
	var l1 := _lobo_perto(2.0)
	var v0 := l1.vida
	await create_timer(3.0).timeout
	var dano1 := v0 - l1.vida
	_m("fase 1: morde de leve (dano 4 por golpe)", dano1 >= 4 and dano1 <= 12, "dano %d em 3 s" % dano1)
	l1.queue_free()
	# fase 2
	jogo.missoes.ativas.append("C2-M3")
	jogo.missoes._concluir("C2-M3")
	await create_timer(0.5).timeout
	_m("fase 2 (queda do 1º obelisco): tamanho 0,85, mais clara, ainda não monta", f.fase == 2 and absf(f._modelo.scale.x - 0.85) < 0.01 and not f.montaria.ativa)
	var tinta2: Color = (f._modelo.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).get_surface_override_material(0).albedo_color
	_m("fase 2: cor mais clara que na fase 1", tinta2.get_luminance() > tinta1.get_luminance())
	jogo.hud.fechar_dialogo()
	jogo._cena = []
	jog.travado = false
	f.global_position = jog.global_position + Vector3(3, 0, 0)
	_tecla_f()
	await create_timer(3.0).timeout
	var h_planando := f.global_position.y - jog.global_position.y
	_m("fase 2: F faz planar a ~3 m", f.modo_voo and h_planando > 1.5 and h_planando < 4.5, "%.1f m" % h_planando)
	await create_timer(5.0).timeout
	_m("fase 2: depois de alguns segundos pousa sozinho", not f.modo_voo)
	_tecla_f()
	_m("fase 2: logo depois não planeia de novo (descansando)", not f.modo_voo)
	# fase 3
	jogo.missoes.ativas.append("C3-M4")
	jogo.missoes._concluir("C3-M4")
	await create_timer(0.5).timeout
	_m("fase 3 (Ferrogris): tamanho 1,0, cor plena, pode ser montada", f.fase == 3 and absf(f._modelo.scale.x - 1.0) < 0.01 and f.montaria.ativa)
	jogo.hud.fechar_dialogo()
	jogo._cena = []
	jog.travado = false
	f._t_recarga = 0.0
	_tecla_f()
	await create_timer(4.0).timeout
	var h3 := f.global_position.y - jog.global_position.y
	_m("fase 3: voo livre a ~8 m", f.modo_voo and h3 > 5.0, "%.1f m" % h3)
	f.modo_voo = false
	await create_timer(3.0).timeout
	f.global_position = jog.global_position + Vector3(3, 0, 0)
	var l3 := _lobo_perto(3.0)
	var v3 := l3.vida
	await create_timer(2.5).timeout
	_m("fase 3: cospe fogo (dano 16) e o fogo aparece", v3 - l3.vida >= 16 and m.find_children("*", "Fogo", true, false).size() > 0, "dano %d" % (v3 - l3.vida))
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
