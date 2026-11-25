class_name PecasDeConstrucao
extends Node3D
## Base dos kits de construção (muralha, rua...): junta centenas de peças simples (caixas, cilindros, prismas) em poucos
## MultiMesh, um por malha + cor + tipo de material, e guarda as colisões num corpo só. Cada kit só diz ONDE vai cada peça
## e de que cor; no fim chama `fechar()`. O tipo do material sai da cor: o kit responde em `_eh_pedra` quais cores são
## pedra (cantaria pintada); as outras são lisas (madeira, ferro, pano) e as marcadas `luz` brilham sozinhas.

var _corpo: StaticBody3D
var _lotes := {}   # "malha|cor|tipo" -> Array[Transform3D]


func _init() -> void:
	_corpo = StaticBody3D.new()
	_corpo.name = "Solidos"
	add_child(_corpo)


func fechar() -> void:
	for chave in _lotes:
		var partes: PackedStringArray = String(chave).split("|")
		var malha: PrimitiveMesh
		if partes[0] == "cilindro":
			var cil := CylinderMesh.new()
			cil.height = 1.0
			cil.radial_segments = 32
			malha = cil
		elif partes[0] == "prisma":
			malha = PrismMesh.new()
		elif partes[0] == "piramide":   # quatro faces e ponta: agulhas de torre e pináculos
			var pir := CylinderMesh.new()
			pir.height = 1.0
			pir.top_radius = 0.0
			pir.radial_segments = 4
			pir.rings = 1
			malha = pir
		else:
			malha = BoxMesh.new()
		var cor := Color.html(partes[1])
		if partes[2] == "luz":
			var m := StandardMaterial3D.new()
			m.albedo_color = cor
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			malha.material = m
		elif partes[2] == "liso":
			var m := StandardMaterial3D.new()
			m.albedo_color = cor
			m.roughness = 0.9
			malha.material = m
		else:
			malha.material = Pedra.material(cor)
		var lista: Array = _lotes[chave]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = malha
		mm.instance_count = lista.size()
		for i in lista.size():
			mm.set_instance_transform(i, lista[i])
		var inst := MultiMeshInstance3D.new()
		inst.name = String(chave).replace("|", "_")
		inst.multimesh = mm
		add_child(inst)


func _eh_pedra(_cor: Color) -> bool:
	return false


func _peca(malha: String, cor: Color, t: Transform3D, luz := false) -> void:
	var chave := "%s|%s|%s" % [malha, cor.to_html(), "luz" if luz else ("pedra" if _eh_pedra(cor) else "liso")]
	if not _lotes.has(chave):
		_lotes[chave] = []
	_lotes[chave].append(t)


func _caixa(pos: Vector3, tam: Vector3, giro: float, cor: Color, colidir: bool, luz := false) -> void:
	_peca("caixa", cor, Transform3D(Basis(Vector3.UP, giro).scaled_local(tam), pos), luz)
	if colidir:
		_solido(pos, tam, giro)


func _cilindro(pos: Vector3, raio: float, altura: float, cor: Color) -> void:
	_peca("cilindro", cor, Transform3D(Basis.from_scale(Vector3(raio * 2.0, altura, raio * 2.0)), pos))


func _solido(pos: Vector3, tam: Vector3, giro: float) -> void:
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = tam
	cs.shape = caixa
	cs.position = pos
	cs.rotation.y = giro
	_corpo.add_child(cs)
