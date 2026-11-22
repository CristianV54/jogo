extends SceneTree
# Fotos das casas de vários povoados e regiões.  godot --path . --resolution 1280x720 --script res://tools/capturar_casas.gd
var jogo: Jogo
var cam: Camera3D


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _foto(nome: String, c: Vector2, d: float, alt: float) -> void:
	var m: Mundo = jogo.mundo
	var y: float = m.terreno.altura_em(c.x, c.y)
	jogo.jogador.global_position = Vector3(c.x, y + 2.0, c.y)
	jogo.jogador.velocity = Vector3.ZERO
	cam.global_position = Vector3(c.x + d * 0.4, y + alt, c.y + d)
	cam.look_at(Vector3(c.x, y + 2.0, c.y))
	await create_timer(3.0).timeout
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/casas_%s.png" % nome)
	print("CAPTURA ", nome)


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
	for id in ["campina", "beira_rio", "pedras_altas", "rio_claro", "pescador", "posto_imperial", "ocre"]:
		if m.povoados.has(id):
			var pv: Node3D = m.povoados[id]["no"]
			var c: Vector2 = m.povoados[id]["centro"]
			await _foto(id, c + m.povoados[id]["dir"] * 0.0, 38.0, 22.0)
	for id in ["valdoria", "castelo_imperial"]:
		var c := MundoDados.centro(id)
		await _foto(id, c + Vector2(0, 40), 60.0, 30.0)
	quit(0)
