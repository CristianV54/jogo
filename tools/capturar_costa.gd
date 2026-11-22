extends SceneTree
# Fotos da costa.  godot --path . --resolution 1280x720 --script res://tools/capturar_costa.gd
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
	await create_timer(3.5).timeout
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/costa_%s.png" % nome)
	print("CAPTURA ", nome)


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jogo.clima.congelado = true
	jogo.clima.definir_hora(11.0)
	jogo.clima.forcar_tempo(Clima.Tempo.LIMPO)
	cam = Camera3D.new()
	cam.far = 4000.0
	cam.fov = 65
	root.add_child(cam)
	cam.current = true
	var m: Mundo = jogo.mundo
	# acha um ponto da costa do oeste e do sul andando de dentro para fora
	var pontos: Array = []
	for par in [[Vector2(-100, 200), Vector2(0, 1)], [Vector2(-500, -500), Vector2(-1, 0)], [Vector2(700, -500), Vector2(1, 0)]]:
		var p: Vector2 = par[0]
		var passo: Vector2 = par[1]
		for i in 400:
			if Costa.distancia(p.x, p.y) < 12.0:
				break
			p += passo * 4.0
		pontos.append(p)
	print("COSTA pontos ", pontos)
	for i in pontos.size():
		var p: Vector2 = pontos[i]
		var para := Vector3(p.x, Costa.NIVEL_MAR, p.y)
		var de := Vector3(p.x, m.terreno.altura_em(p.x, p.y) + 8.0, p.y) + Vector3(randf_range(-1, 1), 0, 0)
		var fora := Vector2(sign(p.x) * 0.0, 0.0)
		await _foto("c%d_perto" % i, Vector3(p.x - 40.0 * sign(p.x), m.terreno.altura_em(p.x - 40.0 * sign(p.x), p.y - 30.0) + 6.0, p.y - 30.0), para, Vector3(p.x - 40.0 * sign(p.x), m.terreno.altura_em(p.x - 40.0 * sign(p.x), p.y - 30.0) + 2.0, p.y - 30.0))
		await _foto("c%d_alto" % i, Vector3(p.x - 160.0 * sign(p.x), 100.0, p.y - 140.0), para, Vector3(p.x - 160.0 * sign(p.x), 25.0, p.y - 140.0))
	quit(0)
