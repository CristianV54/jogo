class_name Efeitos
extends RefCounted
## Efeitos visuais curtos e sem estado.

## Pinta todas as malhas de `raiz` de vermelho por `duracao` segundos (sinal de que levou um golpe).
static func piscar(raiz: Node3D, duracao := 0.18) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.1, 0.1, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var malhas := raiz.find_children("*", "MeshInstance3D", true, false)
	for mi in malhas:
		(mi as MeshInstance3D).material_overlay = mat
	raiz.get_tree().create_timer(duracao).timeout.connect(func() -> void:
		for mi in malhas:
			if is_instance_valid(mi):
				(mi as MeshInstance3D).material_overlay = null)


## O corpo se desfaz: uma nuvem de poeira, o visual encolhe até sumir e, no fim, `no` é liberado.
static func desintegrar(no: Node3D, visual: Node3D, duracao := 1.2) -> void:
	var puff := CPUParticles3D.new()
	puff.one_shot = true
	puff.explosiveness = 0.9
	puff.amount = 28
	puff.lifetime = 1.1
	puff.direction = Vector3.UP
	puff.spread = 70.0
	puff.gravity = Vector3(0.0, -0.6, 0.0)
	puff.initial_velocity_min = 0.8
	puff.initial_velocity_max = 2.0
	puff.scale_amount_min = 0.6
	puff.scale_amount_max = 1.4
	var bola := SphereMesh.new()
	bola.radius = 0.12
	bola.height = 0.24
	bola.radial_segments = 6
	bola.rings = 3
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.55, 0.5, 0.42, 0.7)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bola.material = m
	puff.mesh = bola
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 1.0))
	curva.add_point(Vector2(1.0, 0.0))
	puff.scale_amount_curve = curva
	var pai := no.get_parent()
	pai.add_child(puff)
	puff.global_position = no.global_position + Vector3(0.0, 0.5, 0.0)
	puff.emitting = true
	puff.finished.connect(puff.queue_free)
	var tw := no.create_tween()
	tw.tween_property(visual, "scale", Vector3.ONE * 0.02, duracao).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(no.queue_free)
