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


func _foto(nome: String, espera := 3.0) -> void:
	await create_timer(espera).timeout
	RenderingServer.force_draw()
	var im := root.get_viewport().get_texture().get_image()
	im.convert(Image.FORMAT_RGB8)
	im.save_jpg("tools/capturas/reino/%s.jpg" % nome, 0.9)
	print("CAPTURA ", nome)


func _por(q: Vector2, yaw: float) -> void:
	jogo.jogador.global_position = Vector3(q.x, jogo.mundo.chao_em(q.x, q.y) + 1.5, q.y)
	jogo.jogador.velocity = Vector3.ZERO
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
	var rc: Vector2 = MundoDados.REINO["centro"]
	var cc := MundoDados.centro("castelo_imperial")
	_ver(Vector2(0, 590), Vector2(0, 400))        # chegando pelo sul: muralha, portão e o castelo por cima
	await _foto("01_chegando_pelo_portao_sul", 5.0)
	_ver(Vector2(0, 446), Vector2(0, 250))        # avenida do portão sul, com o castelo no alto ao fundo
	await _foto("02_avenida_do_portao_sul", 4.0)
	_ver(Vector2(200, 346), Vector2(60, 396))     # Rua do Anel: casas dos dois lados
	await _foto("03_rua_do_anel", 4.0)
	_ver(Vector2(228, 228), Vector2(140, 290))    # uma viela entre duas fileiras de sobrados
	await _foto("04_viela", 4.0)
	_ver(Vector2(170, 198), Vector2(110, 240))    # Rua do Castelo, ao pé do rochedo
	await _foto("05_rua_do_castelo", 4.0)
	for item in [["06_praca_do_mercado", "mercado_central"], ["07_quartel_campo_de_treino", "quartel_da_guarda"], ["08_estabulos_do_reino", "estabulos_do_reino"]]:
		var pc: Vector2 = m.povoados[item[1]]["centro"]
		var para_fora := (pc - rc).normalized()   # as praças se abrem da Rua do Castelo para fora
		_ver(pc - para_fora * 24.0, pc + para_fora * 30.0)
		await _foto(item[0], 4.0)
	_ver(Vector2(0, 415), Vector2(0, 480))        # portão sul por dentro, com as sentinelas
	await _foto("09_portao_sul_por_dentro", 4.0)
	_ver(Vector2(22, 452), Vector2(70, 466))      # colado na muralha: a pedra
	await _foto("10_pedra_da_muralha", 3.0)
	_ver(Vector2(0, 285), Vector2(0, 120))        # a subida do castelo
	await _foto("11_subida_do_castelo", 4.0)
	_ver(Vector2(-330, 150), Vector2(0, 0))       # da cidade baixa: o rochedo e o castelo branco lá em cima
	await _foto("12_castelo_visto_da_cidade", 4.0)
	_ver(cc + Vector2(0, 122), cc + Vector2(0, 60))      # portão do castelo, no alto
	await _foto("13_portao_do_castelo", 4.0)
	_ver(cc + Vector2(0, -62), cc + Vector2(0, -100))   # Salão do Trono: o rei, o conselheiro e a guarda real
	await _foto("14_rei_no_salao_do_trono", 5.0)
	# vistas aéreas: liga a vista do reino inteiro (no jogo, praça e castelo a mais de 800 m somem)
	_por(Vector2(0, 430), 0.0)
	await create_timer(1.0).timeout
	m.set_process(false)
	(m.regioes["castelo_imperial"] as Node3D).visible = true
	for pid in m.povoados:
		if (m.povoados[pid]["centro"] as Vector2).distance_to(rc) < 900.0:
			(m.povoados[pid]["no"] as Node3D).visible = true
	jogo.clima._env.fog_enabled = false
	var cam := Camera3D.new()
	cam.far = 6000.0
	cam.fov = 50.0
	root.add_child(cam)
	cam.current = true
	for v in [["15_aerea_como_a_referencia", Vector3(-420, 230, 900), Vector3(0, 30, 0)], ["16_aerea_do_sul", Vector3(0, 560, 950), Vector3(0, 0, 0)], ["17_aerea_de_cima", Vector3(0, 1150, 1), Vector3(0, 0, 0)]]:
		cam.global_position = v[1]
		cam.look_at(v[2])
		await _foto(v[0], 4.0)
	quit(0)
