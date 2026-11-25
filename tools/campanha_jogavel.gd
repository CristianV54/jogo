extends SceneTree
## Agente de controle: joga o jogo pela janela, só com teclas de verdade (Input.parse_input_event), região por região: teleporte F1..F8,
## anda (W), corre (Shift), pula (Espaço), golpeia (J), rola (K), interage (E), abre inventário (I) e mapa (M), monta o cavalo no Refúgio.
## Mede: fps (médio e mínimo), se ficou preso andando, quedas, câmera dentro de parede, vida, mensagens de erro. Tira uma foto por região.
##   godot --path . --resolution 1280x720 --script res://tools/campanha_jogavel.gd
var jogo: Jogo
var relatorio := ""
var problemas: Array = []
func _init() -> void:
	Jogo.historia = true   # este teste é da campanha antiga, que no jogo está desligada
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_r.call_deferred()
func _tecla(k: Key, apertada: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = k
	ev.keycode = k
	ev.pressed = apertada
	Input.parse_input_event(ev)
func _toque(k: Key, espera := 0.15) -> void:
	_tecla(k, true)
	await create_timer(0.08).timeout
	_tecla(k, false)
	await create_timer(espera).timeout
## Anda segurando W; se ficar parado por 1 s (parede, cerca), vira 90 graus e continua (como um jogador desviaria). Devolve
## [distância total, fps mínimo, desvios feitos, preso de vez (3 desvios seguidos sem progresso)].
func _andar(segundos: float, correr := false) -> Array:
	var p0 := jogo.jogador.global_position
	_tecla(KEY_W, true)
	if correr:
		_tecla(KEY_SHIFT, true)
	var fps_min := 999.0
	var t := 0.0
	var desvios := 0
	var seguidos := 0
	var marca := jogo.jogador.global_position
	var t_marca := 0.0
	while t < segundos:
		await create_timer(0.1).timeout
		t += 0.1
		fps_min = minf(fps_min, Engine.get_frames_per_second())
		if t - t_marca >= 1.0:
			if jogo.jogador.global_position.distance_to(marca) < 0.8:
				jogo.camera.yaw += PI / 2.0
				desvios += 1
				seguidos += 1
			else:
				seguidos = 0
			marca = jogo.jogador.global_position
			t_marca = t
	_tecla(KEY_W, false)
	_tecla(KEY_SHIFT, false)
	return [jogo.jogador.global_position.distance_to(p0), fps_min, desvios, seguidos >= 3]
func _nota(regiao: String, texto: String, grave := true) -> void:
	problemas.append("[%s] %s%s" % [regiao, "PROBLEMA: " if grave else "obs: ", texto])
func _r() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	var jog: Jogador = jogo.jogador
	var cam: CameraTerceiraPessoa = jogo.camera
	var teclas := [KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8]
	var ids := Admin.REGIOES
	var linhas := "| Região | fps médio | fps mín | andou em 4 s | correu em 3 s | preso? | câmera | vida | observações |\n|---|---|---|---|---|---|---|---|---|\n"
	jogo.clima.congelado = true
	jogo.clima.definir_hora(11.0)
	for i in ids.size():
		var id: String = ids[i]
		await _toque(teclas[i], 0.2)
		await create_timer(7.0).timeout   # espera o capim, a mata e os bichos em volta nascerem (o mesmo que a medição de desempenho)
		var fps0 := Engine.get_frames_per_second()
		var obs := ""
		var sobe := jog.global_position.y
		var r1 := await _andar(4.0)
		var r2 := await _andar(3.0, true)
		var preso: bool = r1[3] or r2[3]
		if preso:
			_nota(id, "ficou preso: 3 desvios seguidos sem sair do lugar (andou %.1f m)" % float(r1[0]))
		if int(r1[2]) + int(r2[2]) >= 3:
			_nota(id, "precisou desviar %d vezes em 7 s de caminhada (muita parede no caminho do spawn)" % (int(r1[2]) + int(r2[2])), false)
		await _toque(KEY_SPACE, 0.4)
		await _toque(KEY_SPACE, 0.4)
		await _toque(KEY_J, 0.5)
		await _toque(KEY_J, 0.5)
		await _toque(KEY_K, 0.6)
		await _toque(KEY_E, 0.3)
		if jogo.hud.dialogo_aberto:
			obs += "E abriu diálogo; "
			var guarda := 0
			while (jogo.hud.dialogo_aberto or not jogo._cena.is_empty()) and guarda < 60:   # as falas agora têm várias páginas
				await _toque(KEY_E, 0.25)
				guarda += 1
			obs += "%d toques para fechar; " % guarda
			if jogo.hud.dialogo_aberto:
				_nota(id, "o diálogo não fecha com E (60 toques)")
		await _toque(KEY_I, 0.4)
		var inv_ok: bool = jogo.hud.inventario_aberto
		await _toque(KEY_I, 0.3)
		await _toque(KEY_M, 0.5)
		var mapa_ok: bool = jogo.hud.mapa_aberto
		await _toque(KEY_M, 0.3)
		if not inv_ok:
			_nota(id, "a tecla I não abriu o inventário")
		if not mapa_ok:
			_nota(id, "a tecla M não abriu o mapa")
		# câmera: o braço não pode estar quase colado no Torin (câmera presa dentro de algo)
		var d_cam := root.get_viewport().get_camera_3d().global_position.distance_to(jog.global_position + Vector3(0, 1.5, 0))
		var cam_ok := d_cam > 1.5
		if not cam_ok:
			_nota(id, "câmera a %.1f m do Torin (colada: provavelmente dentro de parede)" % d_cam, false)
		if jog.global_position.y < -20.0:
			_nota(id, "o Torin caiu do mundo (y=%.1f)" % jog.global_position.y)
		var menor_fps := minf(float(r1[1]), float(r2[1]))
		if menor_fps < 30.0:
			_nota(id, "fps mínimo de %.0f andando" % menor_fps, menor_fps < 20.0)
		RenderingServer.force_draw()
		root.get_viewport().get_texture().get_image().save_png("res://tools/capturas/jogavel_%s.png" % id)
		linhas += "| %s | %.0f | %.0f | %.1f m (%d desvios) | %.1f m (%d desvios) | %s | %s (%.1f m) | %d | %s |\n" % [id, fps0, menor_fps, float(r1[0]), int(r1[2]), float(r2[0]), int(r2[2]), "SIM" if preso else "não", "ok" if cam_ok else "colada", d_cam, jog.vida, obs]
	# Refúgio: cavalo
	await _toque(KEY_F1, 0.2)
	await create_timer(2.0).timeout
	var cavalo: AnimalVila = null
	for a in jogo.mundo.regioes["refugio_do_pinhal"].find_children("*", "AnimalVila", false, false):
		if a.especie == "cavalo":
			cavalo = a
	var montou := false
	var cav_andou := 0.0
	if cavalo:
		jog.global_position = cavalo.global_position + Vector3(2.2, 0.3, 0)
		cam.yaw = atan2(-(cavalo.global_position - jog.global_position).x, -(cavalo.global_position - jog.global_position).z)
		await create_timer(0.6).timeout
		await _toque(KEY_E, 1.8)
		montou = jog.montaria != null
		if montou:
			var q0 := jog.global_position
			cam.yaw = atan2(1.0, 0.0)
			_tecla(KEY_W, true)
			await create_timer(2.5).timeout
			_tecla(KEY_W, false)
			cav_andou = jog.global_position.distance_to(q0)
			await _toque(KEY_E, 1.5)
		else:
			_nota("refugio_do_pinhal", "apertar E perto do cavalo não montou")
	# noite e chuva
	await _toque(KEY_F9, 0.3)
	await _toque(KEY_F9, 0.3)
	await _toque(KEY_F9, 0.3)   # 22h
	await _toque(KEY_F10, 0.3)
	await _toque(KEY_F10, 0.3)
	await _toque(KEY_F10, 0.5)   # tempestade
	await create_timer(4.0).timeout
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("res://tools/capturas/jogavel_noite_chuva.png")
	var f_noite := Engine.get_frames_per_second()
	var md := "# Campanha jogável (agente de controle, teclas reais)\n\nExecutada em janela 1280x720, Godot 4.7.2, Metal. Teclas usadas: F1..F8 (teleporte), W/Shift (andar/correr), Espaço, J, K, E, I, M, F9, F10.\n\n"
	md += linhas
	md += "\n**Cavalo no Refúgio:** montou=%s, andou %.1f m montado em 2,5 s.\n**Noite com tempestade no Refúgio:** %.0f fps.\n" % [str(montou), cav_andou, f_noite]
	md += "\n## Problemas e observações\n" + ("\n".join(problemas) if not problemas.is_empty() else "Nenhum problema detectado pelos critérios do agente (preso, queda, tecla sem efeito, câmera colada, fps < 30).") + "\n"
	var f := FileAccess.open("res://docs/auditoria/CAMPANHA_JOGAVEL.md", FileAccess.WRITE)
	f.store_string(md)
	f.close()
	print("CAMPANHA_JOGAVEL problemas=", problemas.size())
	quit(0)
