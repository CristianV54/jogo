class_name Acessorios
extends RefCounted
## Peças que transformam um modelo existente em outro bicho: chifres no cavalo (cervo), orelhas no cachorro (urso, coelho).
## Cada peça é presa ao osso "Head" por um BoneAttachment3D, então acompanha a cabeça na animação.
## Modelos com esqueleto de quadrúpede do pacote Farm Animals; medidas em metros, no espaço do osso.

static func aplicar(visual: Node3D, nome: String) -> void:
	if nome == "":
		return
	var esq := visual.find_child("Skeleton3D", true, false) as Skeleton3D
	if esq == null or esq.find_bone("Head") < 0:
		return
	var anexo := BoneAttachment3D.new()
	anexo.name = "Acessorios"
	anexo.bone_name = "Head"
	esq.add_child(anexo)
	# Alinha os eixos aos do modelo (x direita, y cima, z frente) e compensa a escala do esqueleto (o cão tem 0,4):
	# as medidas abaixo são em metros do modelo, a partir da origem do osso da cabeça.
	var repouso := esq.get_bone_global_rest(esq.find_bone("Head"))
	var u := visual.global_transform.basis.get_scale().x / esq.global_transform.basis.get_scale().x
	var eixos := Node3D.new()
	eixos.transform = Transform3D(repouso.basis.inverse(), Vector3.ZERO)
	eixos.scale = Vector3.ONE * u
	anexo.add_child(eixos)
	match nome:
		"chifres":
			for lado in [-1.0, 1.0]:
				_haste(eixos, Vector3(lado * 0.07, 0.05, 0.06), Vector3(lado * 0.2, 0.55, 0.0), 0.03, Color(0.78, 0.7, 0.52))
				_haste(eixos, Vector3(lado * 0.14, 0.3, 0.03), Vector3(lado * 0.07, 0.62, 0.12), 0.02, Color(0.78, 0.7, 0.52))
		"orelhas_redondas":
			for lado in [-1.0, 1.0]:
				_bola(eixos, Vector3(lado * 0.11, 0.1, 0.0), 0.055, Color(0.2, 0.13, 0.08))
		"orelhas_longas":
			for lado in [-1.0, 1.0]:
				_haste(eixos, Vector3(lado * 0.04, 0.08, 0.0), Vector3(lado * 0.06, 0.42, -0.04), 0.035, Color(0.6, 0.55, 0.46))


static func _haste(pai: Node3D, de: Vector3, para: Vector3, raio: float, cor: Color) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = raio * 0.4
	c.bottom_radius = raio
	c.height = de.distance_to(para)
	c.radial_segments = 5
	c.material = _mat(cor)
	mi.mesh = c
	pai.add_child(mi)
	mi.position = (de + para) / 2.0
	mi.basis = Basis(Quaternion(Vector3.UP, (para - de).normalized()))   # o cilindro tem o eixo no Y


static func _bola(pai: Node3D, pos: Vector3, raio: float, cor: Color) -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = raio
	s.height = raio * 2.0
	s.radial_segments = 6
	s.rings = 3
	s.material = _mat(cor)
	mi.mesh = s
	mi.position = pos
	pai.add_child(mi)


static func _mat(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.9
	return m
