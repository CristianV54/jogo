extends SceneTree
# Fotos das plantações: Refúgio, Fazenda Campina e Vila Campos Altos.  godot --path . --resolution 1280x720 --script res://tools/capturar_plantacao.gd
var jogo: Jogo
var cam: Camera3D


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _foto(nome: String, de: Vector3, para: Vector3, jog: Vector3) -> void:
	jogo.jogador.global_position = jog
	jogo.jogador.velocity = Vector3.ZERO
	cam.global_position = de
	cam.look_at(para)
	await create_timer(3.0).timeout
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/plantacao_%s.png" % nome)
	print("CAPTURA ", nome, " fps=", Engine.get_frames_per_second())


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jogo.clima.congelado = true
	jogo.clima.definir_hora(10.5)
	jogo.clima.forcar_tempo(Clima.Tempo.LIMPO)
	cam = Camera3D.new()
	cam.far = 3000.0
	cam.fov = 65
	root.add_child(cam)
	cam.current = true
	var m: Mundo = jogo.mundo
	var h := func(x: float, z: float) -> float: return m.terreno.altura_em(x, z)
	await _foto("horta_refugio", Vector3(15, 6.0, -2), Vector3(15, 0.5, -14), Vector3(0, 2, 0))
	var c: Vector2 = m.povoados["campina"]["centro"]
	var pov: Node3D = m.povoados["campina"]["no"]
	var campos: Array[Node] = pov.find_children("*", "Plantacao", true, false)
	var f: Node3D = campos[0]
	var fp := Vector2(f.global_position.x, f.global_position.z)
	var fy: float = h.call(fp.x, fp.y)
	var jog := Vector3(fp.x + 20.0, fy + 2.0, fp.y)
	await _foto("fazenda_alto", Vector3(fp.x - 18.0, fy + 18.0, fp.y + 22.0), Vector3(fp.x, fy, fp.y), jog)
	await _foto("fazenda_baixo", Vector3(fp.x - 9.0, fy + 1.8, fp.y + 12.0), Vector3(fp.x + 2.0, fy + 0.7, fp.y - 2.0), jog)
	quit(0)
