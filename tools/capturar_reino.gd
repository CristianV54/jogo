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
	_por(Vector2(0, 560), 0.0)            # do lado de fora do portão sul, olhando a muralha
	await _foto("1_portao_sul", 5.0)
	_por(Vector2(0, 430), 0.0)            # logo depois do portão: Valdoria ao fundo
	await _foto("2_dentro_do_portao", 4.0)
	var b: Vector2 = m.povoados["bairro_dos_teceloes"]["centro"]
	_por(b + (Vector2(0, -60) - b).normalized() * 75.0, atan2(-(b - Vector2(0, -60)).x, -(b - Vector2(0, -60)).y))
	await _foto("3_bairro_dos_teceloes", 4.0)
	var mc: Vector2 = m.povoados["mercado_do_poente"]["centro"]
	_por(mc + Vector2(0, 62), 0.0)
	await _foto("4_mercado_do_poente", 4.0)
	var f: Vector2 = m.povoados["feira_sul"]["centro"]
	_por(f + Vector2(-70, 20), -PI / 2.0)
	await _foto("5_feira_do_portao_sul", 4.0)
	_ver(Vector2(-205, -59), Vector2(-420, -60))   # Rua do Meio, olhando para o oeste: mercado, casas e o portão oeste ao fundo
	await _foto("6_rua_do_meio", 4.0)
	_por(Vector2(-640, -60), PI / 2.0 + PI)   # do lado de fora do portão oeste, olhando para dentro
	await _foto("6b_portao_oeste_por_fora", 4.0)
	_ver(Vector2(60, 349), Vector2(260, 290))    # Rua do Anel, ao sul: fileiras de casas dos dois lados
	await _foto("6c_rua_do_anel_sul", 4.0)
	var tr: Vector2 = m.ponto_na_estrada("travessa_03", 10.0)[0]
	_ver(tr, m.ponto_na_estrada("travessa_03", 110.0)[0])   # uma travessa, da Rua do Anel para a muralha
	await _foto("6c2_travessa", 4.0)

	var rc: Vector2 = MundoDados.REINO["centro"]
	for item in [["6d_quartel_campo_de_treino", "quartel_da_guarda", 1.0, 26.0], ["6e_estabulos_do_reino", "estabulos_do_reino", -1.0, 24.0], ["6f_guarita_do_portao_oeste", "guarita_oeste", -1.0, 22.0]]:
		var cc: Vector2 = m.povoados[item[1]]["centro"]
		var para_dentro := (rc - cc).normalized() * float(item[2])   # para onde o lugar se estende
		_ver(cc - para_dentro * float(item[3]), cc + para_dentro * 20.0)
		await _foto(item[0], 4.0)
	_ver(Vector2(0, -535), Vector2(0, -640))     # portão norte, por dentro, com as sentinelas
	await _foto("6f2_portao_norte_por_dentro", 4.0)
	_ver(Vector2(-95, 478), Vector2(-99, 502))   # colado na muralha (por dentro, a sudoeste do portão sul): a textura da pedra
	await _foto("6g_pedra_da_muralha_de_perto", 3.0)
	_ver(Vector2(0, 330), Vector2(0, -300))      # da Rua do Anel, ao sul: as torres do castelo por cima de Valdoria
	await _foto("6h_castelo_visto_da_rua", 4.0)
	_ver(Vector2(0, -90), Vector2(0, -330))      # ao pé do castelo
	await _foto("6i_castelo_de_perto", 4.0)
	# vista aérea: liga a vista do reino inteiro (no jogo, o que está a mais de 800 m some)
	_por(Vector2(0, 380), 0.0)
	await create_timer(1.0).timeout
	m.set_process(false)
	for id in ["valdoria", "castelo_imperial"]:
		(m.regioes[id] as Node3D).visible = true
	for pid in m.povoados:
		if (m.povoados[pid]["centro"] as Vector2).distance_to(MundoDados.REINO["centro"]) < 900.0:
			(m.povoados[pid]["no"] as Node3D).visible = true
	jogo.clima._env.fog_enabled = false
	var cam := Camera3D.new()
	cam.far = 6000.0
	cam.fov = 55.0
	root.add_child(cam)
	cam.current = true
	cam.global_position = Vector3(0, 620, 1150)
	cam.look_at(Vector3(0, 0, -100))
	await _foto("7_aerea_do_reino_vista_do_sul", 4.0)
	cam.global_position = Vector3(-1000, 520, -60)
	cam.look_at(Vector3(0, 0, -60))
	await _foto("8_aerea_do_reino_vista_do_oeste", 4.0)
	quit(0)
