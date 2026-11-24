extends SceneTree
## Diagnóstico: anda de verdade rumo ao leste a partir de x=-175 (estrada do Pomar) e imprime onde o Torin trava.
var jogo: Jogo
var jog: Jogador
func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	jog = jogo.get_node("Jogador")
	_r.call_deferred()
func _r() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	await create_timer(2.0).timeout
	jog.global_position = Vector3(-175.0, jogo.mundo.chao_em(-175.0, 0.0) + 0.5, 0.0)
	await create_timer(2.5).timeout
	var ss := jogo.get_world_3d().direct_space_state
	for x0 in range(-172, -146, 2):
		var qd := PhysicsRayQueryParameters3D.create(Vector3(x0, 8.0, 0.0), Vector3(x0, -5.0, 0.0))
		qd.collision_mask = 1
		var hd := ss.intersect_ray(qd)
		print("ALTURA x=", x0, " y=", snapped(hd.position.y, 0.01) if not hd.is_empty() else "sem chão", " chao_em=", snapped(jogo.mundo.chao_em(x0, 0.0), 0.01))
	for z0 in []:
		for y0 in [0.3, 1.0, 2.5]:
			var q := PhysicsRayQueryParameters3D.create(Vector3(-170.0, y0, z0), Vector3(-150.0, y0, z0))
			q.collision_mask = 0xFFFFF
			var h := ss.intersect_ray(q)
			print("RAIO z=", z0, " y=", y0, " -> ", (str(h.collider.get_path()) + " layer=" + str((h.collider as CollisionObject3D).collision_layer) + " x=" + str(snapped(h.position.x, 0.1))) if not h.is_empty() else "livre")
	for z in [0.0]:
		for x0 in [-175.0, -200.0]:
			jog.global_position = Vector3(x0, jogo.mundo.chao_em(x0, z) + 0.5, z)
			jog.velocity = Vector3.ZERO
			await create_timer(2.5).timeout
			jogo.camera.yaw = atan2(-1.0, 0.0)
			jog.rotation.y = jogo.camera.yaw
			var x_ini := jog.global_position.x
			jog.entrada_forcada = Vector2(0, -1)
			await create_timer(4.0).timeout
			jog.entrada_forcada = Vector2.ZERO
			print("DIAG z=", z, " de x=", x_ini, " -> x=", snapped(jog.global_position.x, 0.1), " z=", snapped(jog.global_position.z, 0.1), " andou ", snapped(jog.global_position.x - x_ini, 0.1), " m em 4 s")
	quit(0)
