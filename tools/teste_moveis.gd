extends SceneTree
# Na cena principal: o jogador entra na Cabana1 pela porta e não atravessa o baú nem a mesa.
#   godot --path . --resolution 1280x720 --script res://tools/teste_moveis.gd
var jogo: Jogo
var jog: Jogador


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	jog = jogo.get_node("Jogador")
	_rodar.call_deferred()


func esperar(s: float) -> void:
	await create_timer(s).timeout


func andar_para(casa: Node3D, local_ini: Vector3, local_dir: Vector3, segundos: float) -> Vector3:
	jog.global_position = casa.to_global(local_ini)
	jog.velocity = Vector3.ZERO
	var dir := casa.global_transform.basis * local_dir
	jogo.camera.yaw = atan2(-dir.x, -dir.z)
	jog.rotation.y = jogo.camera.yaw
	await esperar(0.5)
	jog.entrada_forcada = Vector2(0, -1)
	await esperar(segundos)
	jog.entrada_forcada = Vector2.ZERO
	await esperar(0.3)
	return casa.to_local(jog.global_position)


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await esperar(0.2)
	await esperar(2.0)
	var casa: Node3D = jogo.area.get_node("Cabana1")
	var ok := true
	var p := await andar_para(casa, Vector3(0, 0.5, 4.8), Vector3(0, 0, -1), 2.5)
	print("ENTRADA pela porta: parou em local ", p, " (parede do fundo em z=-2.55)")
	var entrou := p.z < 2.0 and absf(p.x) < 2.6
	print("  ", "PASSOU" if entrou else "FALHOU", " entrou na casa pela porta")
	ok = ok and entrou
	var q := await andar_para(casa, Vector3(-1.6, 0.5, 1.6), Vector3(0, 0, -1), 2.0)
	print("BAU: parou em local ", q, " (baú ocupa z de -0.08 a 0.68 em x -2.25..-0.97)")
	var barrado := q.z > 0.6
	print("  ", "PASSOU" if barrado else "FALHOU", " baú barrou o jogador")
	ok = ok and barrado
	var r := await andar_para(casa, Vector3(0.9, 0.5, 0.4), Vector3(1, 0, 0), 1.5)
	print("MESA: parou em local ", r, " (mesa começa em x≈1.0)")
	var mesa := r.x < 1.0
	print("  ", "PASSOU" if mesa else "FALHOU", " mesa barrou o jogador")
	ok = ok and mesa
	print("RESULTADO_MOVEIS ", "OK" if ok else "FALHOU")
	quit(0)
