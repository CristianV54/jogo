extends SceneTree
# A câmera de 3ª pessoa dentro da casa do Vane: 8 combinações de giro e inclinação, com captura e verificação numérica.
#   godot --path . --resolution 960x540 --script res://tools/teste_camera_casa.gd
const PASTA := "tools/capturas/"
var jogo: Jogo
var falhas := 0
func _init() -> void:
	DirAccess.make_dir_recursive_absolute(PASTA)
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()
func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.2).timeout
	await create_timer(1.0).timeout
	var casa: Node3D = jogo.area.get_node("CasaDoVane")
	var jog: Jogador = jogo.jogador
	var cam: CameraTerceiraPessoa = jogo.camera
	jog.global_position = casa.global_transform * Vector3(1.0, 0.3, 0.0)   # dentro, no meio
	await create_timer(0.8).timeout
	var n := 0
	for pitch in [-0.2, -1.0]:
		for yaw in [0.0, PI / 2.0, PI, -PI / 2.0]:
			cam.yaw = yaw
			cam.pitch = pitch
			await create_timer(0.5).timeout
			var lente: Camera3D = cam.get_node("Braco/Lente")
			var p := lente.global_position
			var l := casa.global_transform.affine_inverse() * p
			# a lente tem que ficar dentro da planta (com 0,3 m de folga) OU, se saiu, não pode estar atrás de uma parede fechada
			var dentro := absf(l.x) < 4.0 and absf(l.z) < 6.0
			# altura do telhado nesse x (casa 4 colunas = 8 m de largura): placa de colisão: 2,22 m em x=±5,1 até 8,55 m em x=0
			var y_telhado := 2.22 + (8.55 - 2.22) * (1.0 - clampf(absf(l.x) / 5.1, 0.0, 1.0))
			var abaixo_do_telhado := l.y < y_telhado - 0.45 or absf(l.x) > 5.1
			print("CAMERA pitch=", pitch, " yaw=", snappedf(yaw, 0.01), " lente_local=", l.snapped(Vector3(0.01, 0.01, 0.01)), " dentro_da_planta=", dentro, " y_do_telhado_ali=", snappedf(y_telhado, 0.01), " lente_abaixo_do_telhado=", abaixo_do_telhado)
			if not abaixo_do_telhado:
				falhas += 1
			root.get_viewport().get_texture().get_image().save_png(PASTA + "camcasa_%d.png" % n)
			n += 1
	print("RESULTADO_CAMERA ", "OK" if falhas == 0 else "FALHAS %d" % falhas)
	quit(0 if falhas == 0 else 1)
