extends SceneTree
# Fotos do REINO (Valdoria grande): vista aérea da muralha com a cidade, o castelo e os bairros; portão sul; um bairro;
# um mercado; a rua do anel. Saída em tools/capturas/reino/.
#   godot --path . --resolution 1280x720 --script res://tools/capturar_reino.gd
var jogo: Jogo


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


## Com argumentos depois de `--` (ex.: `-- 02 04 rua`), só tira as fotos cujo nome contém um deles (rodada rápida).
func _foto(nome: String, espera := 3.0) -> void:
	var filtros := OS.get_cmdline_user_args()
	var quer := filtros.is_empty()
	for f in filtros:
		if nome.contains(f):
			quer = true
	if not quer:
		return
	await create_timer(espera).timeout
	RenderingServer.force_draw()
	var im := root.get_viewport().get_texture().get_image()
	im.convert(Image.FORMAT_RGB8)
	im.save_jpg("tools/capturas/reino/%s.jpg" % nome, 0.9)
	print("CAPTURA ", nome)


func _por(q: Vector2, yaw: float) -> void:
	jogo.jogador.global_position = Vector3(q.x, jogo.mundo.chao_em(q.x, q.y) + 1.5, q.y)
	jogo.jogador.velocity = Vector3.ZERO
	jogo._ultimo_chao_seguro = Vector3.INF
	jogo.camera.yaw = yaw


## Põe o Torin em `p` com a câmera olhando para `alvo`.
func _ver(p: Vector2, alvo: Vector2) -> void:
	var d := alvo - p
	_por(p, atan2(-d.x, -d.y))


func _rodar() -> void:
	DirAccess.make_dir_recursive_absolute("res://tools/capturas/reino")
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	var m: Mundo = jogo.mundo
	jogo.clima.congelado = true
	jogo.clima.definir_hora(11.0)
	jogo.clima.forcar_tempo(Clima.Tempo.LIMPO)
	var e := MundoDados.PENHASCO_EIXOS
	var topo := MundoDados.PENHASCO_ALTURA
	var sul: Vector2 = m.muralha.portoes[0]
	for g in m.muralha.portoes:
		if g.y > sul.y:
			sul = g
	_ver(sul + Vector2(0, 110), sul)                     # chegando pelo sul: muralha, portão, a cidade e a cidadela no alto
	await _foto("01_chegando_pelo_portao_sul", 5.0)
	_ver(sul + Vector2(0, -24), Vector2(0, 0))           # avenida do portão sul, com o penhasco e a cidadela ao fundo
	await _foto("02_avenida_do_portao_sul", 4.0)
	_ver(Vector2(0, 178), Vector2(0, 120))               # praça do mercado, ao pé do penhasco
	await _foto("03_praca_do_mercado", 4.0)
	var casario_f := m.get_node("CasarioDoReino") as CasarioDoReino
	var rua_z := 170.0
	for rz in casario_f.ruas:   # a rua de casas mais perto de z = 190, ao sul da praça
		if absf(rz - 190.0) < absf(rua_z - 190.0):
			rua_z = rz
	_ver(Vector2(-12, rua_z), Vector2(-160, rua_z))      # uma rua de casas, da avenida para oeste
	await _foto("04_rua_de_casas", 4.0)
	_ver(Vector2(60, 108), Vector2(140, 20))             # rua em anel, com a rocha do penhasco de um lado e casas do outro
	await _foto("05_rua_do_penhasco", 4.0)
	for item in [["06_quartel_campo_de_treino", "quartel_da_guarda", 2.0], ["07_estabulos_do_reino", "estabulos_do_reino", 14.0], ["08_catedral", "catedral_de_valdoria", 14.0]]:   # o último número: recuo da câmera (no quartel há casa logo atrás)
		var pv: Dictionary = m.povoados[item[1]]
		var longe := Vector2(-(pv["dir"] as Vector2).y, (pv["dir"] as Vector2).x) * float(pv["lado"])
		_ver((pv["centro"] as Vector2) - longe * float(item[2]), (pv["centro"] as Vector2) + longe * 30.0)
		await _foto(item[0], 4.0)
	for item in [["20_vila_campos_altos", "campos_altos", 16.0], ["21_fazenda_imperial", "fazenda_imperial", 16.0], ["22_cabana_do_pescador", "pescador", 14.0]]:   # povoados de fora da muralha
		var pv2: Dictionary = m.povoados[item[1]]
		var longe2 := Vector2(-(pv2["dir"] as Vector2).y, (pv2["dir"] as Vector2).x) * float(pv2["lado"])
		_ver((pv2["centro"] as Vector2) - longe2 * float(item[2]), (pv2["centro"] as Vector2) + longe2 * 30.0)
		await _foto(item[0], 6.0)
	var pe := Vector2(-cos(MundoDados.RAMPA_TS) * e.x * 1.5, sin(MundoDados.RAMPA_TS) * e.y * 1.5)
	_ver(pe + Vector2(16, 6), Vector2(40, 50))           # o pé da rampa, a leste
	await _foto("09_pe_da_rampa", 4.0)
	var meio_r := (MundoDados.RAMPA_R0 + MundoDados.RAMPA_R1) / 2.0
	var na_rampa := func(graus: float) -> Vector2: return Vector2(-cos(deg_to_rad(graus)) * e.x * meio_r, sin(deg_to_rad(graus)) * e.y * meio_r)
	_ver(na_rampa.call(110.0), na_rampa.call(70.0))      # subindo a rampa, na face sul: a cidade lá embaixo
	await _foto("10_subindo_a_rampa", 4.0)
	_ver(na_rampa.call(30.0), Vector2(-e.x * 0.9, 0))    # alto da rampa: o portão da cidadela
	await _foto("11_portao_da_cidadela", 4.0)
	_ver(Vector2(-50, 2), Vector2(0, -8))                # pátio da cidadela: o palácio e as torres
	await _foto("12_patio_da_cidadela", 4.0)
	_ver(Vector2(5, 14.5), Vector2(5, 26))               # a porta do Salão do Trono
	await _foto("13_porta_do_salao", 4.0)
	_ver(Vector2(-6, 25.4), Vector2(20, 25.4))           # dentro do salão: o rei, o conselheiro e a guarda real
	await _foto("14_rei_no_salao_do_trono", 5.0)
	_ver(Vector2(-150, 34), Vector2(-260, 36))            # avenida do oeste, com gente indo e vindo
	await _foto("14a_avenida_do_oeste_com_gente", 5.0)
	jogo.clima.definir_hora(20.5)                        # à noite: janelas acesas, lampiões e vitrais
	_ver(sul + Vector2(0, -30), Vector2(0, 0))
	await _foto("14c_avenida_a_noite", 5.0)
	var pcat: Vector2 = m.povoados["catedral_de_valdoria"]["centro"]
	_ver(pcat + Vector2(-20, -52), pcat + Vector2(28, -4))
	await _foto("14d_catedral_a_noite", 5.0)
	jogo.clima.definir_hora(11.0)
	var plav: Vector2 = m.povoados["lavoura_do_sul"]["centro"]
	_ver(plav - plav.normalized() * 34.0, plav + plav.normalized() * 30.0)   # uma lavoura de verdade, fora da muralha
	await _foto("14b_lavoura", 4.0)
	# vistas aéreas: liga a vista do reino inteiro (no jogo, as praças a mais de 800 m somem)
	_por(sul + Vector2(0, -20), 0.0)
	await create_timer(1.0).timeout
	m.set_process(false)
	for pid in m.povoados:
		if (m.povoados[pid]["centro"] as Vector2).length() < 900.0:
			(m.povoados[pid]["no"] as Node3D).visible = true
	jogo.clima._env.fog_enabled = false
	var cam := Camera3D.new()
	cam.far = 6000.0
	root.add_child(cam)
	cam.current = true
	jogo.clima.definir_hora(17.1)   # fim de tarde, como na referência do Cristian
	cam.fov = 42.0
	cam.global_position = Vector3(-260, 130, 640)
	cam.look_at(Vector3(0, 70, 0))
	await _foto("15_como_a_referencia_fim_de_tarde", 5.0)
	jogo.clima.definir_hora(11.0)
	cam.fov = 50.0
	for v in [["15b_aerea_de_dia", Vector3(-320, 190, 620), Vector3(0, 60, 0)], ["15c_cidadela_de_perto", Vector3(-150, 150, 170), Vector3(0, 95, -5)], ["16_aerea_do_leste", Vector3(650, 240, 60), Vector3(0, 50, 0)], ["17_planta_de_cima", Vector3(0, 800, 1), Vector3(0, 0, 0)]]:
		cam.global_position = v[1]
		cam.look_at(v[2])
		await _foto(v[0], 4.0)
	quit(0)
