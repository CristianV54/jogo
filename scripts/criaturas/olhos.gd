class_name Olhos
extends RefCounted
## Olhos para os bichos dos pacotes (que vêm sem olho). Dois olhos por animal, presos ao osso da cabeça por um BoneAttachment3D,
## então acompanham a animação. Cada olho é ASSENTADO NA PELE: de fora da cabeça sai um raio em direção ao eixo dela e o olho
## fica onde o raio toca a malha (calculada na pose de repouso, com os pesos dos ossos), meio afundado. Assim ele não flutua
## nem salta para fora, seja qual for a largura da cabeça. A direção do raio vem de dois ângulos por espécie: quanto sobe
## (elevação) e quanto vira para a frente (0 = de lado, 90 = de frente). Calibrar olhando o close da cabeça em tools/bancada.gd.
## O cálculo é feito uma vez por espécie e modelo e guardado.

const ESQUELETO_FAZENDA := ["Head", "Head_end"]
const ESQUELETO_LOBO := ["Bone.003", "Bone.003_end"]

# especie -> [ossos, t (0 = base da cabeça, 1 = ponta do focinho), elevação (graus), frontal (graus), raio (fração do comprimento
#             da cabeça), cor do olho, cor da pupila ou null (olho escuro inteiro, sem pupila separada)]
const TABELA := {
	"vaca": [ESQUELETO_FAZENDA, 0.4, 25, 30, 0.07, Color(0.1, 0.06, 0.04), null],
	"ovelha": [ESQUELETO_FAZENDA, 0.4, 25, 35, 0.07, Color(0.1, 0.07, 0.04), null],
	"porco": [ESQUELETO_FAZENDA, 0.5, 20, 52, 0.06, Color(0.08, 0.05, 0.04), null],
	"cavalo": [ESQUELETO_FAZENDA, 0.35, 25, 25, 0.065, Color(0.1, 0.06, 0.03), null],
	"cervo": [ESQUELETO_FAZENDA, 0.35, 25, 25, 0.075, Color(0.09, 0.05, 0.03), null],
	"cao": [ESQUELETO_FAZENDA, 0.2, 35, 45, 0.12, Color(0.12, 0.07, 0.04), null],
	"urso": [ESQUELETO_FAZENDA, 0.2, 35, 45, 0.1, Color(0.08, 0.05, 0.03), null],
	"cao_guerra": [ESQUELETO_FAZENDA, 0.2, 35, 45, 0.1, Color(0.75, 0.12, 0.06), Color(0.03, 0.02, 0.02)],
	"javali": [ESQUELETO_FAZENDA, 0.5, 20, 52, 0.06, Color(0.3, 0.07, 0.04), null],
	"lobo": [ESQUELETO_LOBO, 0.25, 40, 60, 0.062, Color(0.88, 0.62, 0.1), Color(0.03, 0.02, 0.02)],
}

static var _guardados: Dictionary = {}   # "especie|malha" -> o que _calcular devolve


static func aplicar(visual: Node3D, especie: String) -> void:
	if not TABELA.has(especie):
		return
	var esq := visual.find_child("Skeleton3D", true, false) as Skeleton3D
	if esq == null:
		return
	var cfg: Array = TABELA[especie]
	var ossos: Array = cfg[0]
	var ih := esq.find_bone(ossos[0])
	var ie := esq.find_bone(ossos[1])
	if ih < 0 or ie < 0:
		return
	var malhas: Array[MeshInstance3D] = []
	for mi in esq.find_children("*", "MeshInstance3D", true, false):
		if (mi as MeshInstance3D).mesh != null:
			malhas.append(mi)
	if malhas.is_empty():
		return
	var chave := especie + "|" + malhas[0].mesh.resource_path
	if not _guardados.has(chave):
		_guardados[chave] = _calcular(esq, malhas, ih, ie, cfg)
	var dados: Array = _guardados[chave]
	var raio: float = dados[1]
	var anexo := BoneAttachment3D.new()
	anexo.name = "Olhos"
	anexo.bone_name = ossos[0]
	esq.add_child(anexo)
	for par in dados[0]:
		var olhar: Vector3 = par[1]   # para onde a pupila aponta: para fora da pele, puxado para a frente
		var cima: Vector3 = par[2]
		var olho := Node3D.new()
		olho.name = "Olho"
		olho.position = par[0]
		anexo.add_child(olho)
		_bola(olho, Vector3.ZERO, raio, cfg[5], 0.3)
		if cfg[6] != null:   # pupila: um disco escuro deitado sobre a íris (uma bola aqui ficava saltada para fora do olho)
			_disco(olho, olhar * raio * 0.9, olhar, cima, raio * 0.5, 0.22, cfg[6], 0.2)
		_disco(olho, (olhar + cima * 0.42).normalized() * raio * 0.99, olhar, cima, raio * 0.17, 0.4, Color(1, 1, 1), 0.1)   # brilho: dá vida ao olhar


## Acha, na pose de repouso, onde cada olho assenta. Devolve [[[posição, olhar, cima] por olho], raio], no espaço do osso da cabeça.
static func _calcular(esq: Skeleton3D, malhas: Array[MeshInstance3D], ih: int, ie: int, cfg: Array) -> Array:
	var rep_h := esq.get_bone_global_rest(ih)
	var rep_e := esq.get_bone_global_rest(ie)
	var focinho := rep_e.origin - rep_h.origin
	var comp := focinho.length()
	var cima := (esq.global_transform.basis.orthonormalized().inverse() * Vector3.UP).normalized()   # "cima" do mundo, no espaço do esqueleto
	var frente := (focinho - cima * focinho.dot(cima)).normalized()                                    # para onde a cabeça aponta, na horizontal
	var lado := cima.cross(frente).normalized()
	var raio: float = comp * float(cfg[4])
	# triângulos da cabeça, no espaço do esqueleto
	var familia := {ih: true}
	for i in esq.get_bone_count():   # o osso da cabeça e os filhos (orelhas, focinho)
		var p := esq.get_bone_parent(i)
		while p >= 0:
			if p == ih:
				familia[i] = true
				break
			p = esq.get_bone_parent(p)
	var tris := PackedVector3Array()
	var soma_lado := 0.0
	var n_lado := 0
	for mi in malhas:
		var pele := mi.skin
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			if arr[Mesh.ARRAY_BONES] == null or arr[Mesh.ARRAY_WEIGHTS] == null:
				continue
			var bs: PackedInt32Array = arr[Mesh.ARRAY_BONES]
			var ws: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
			var por := bs.size() / vs.size()
			var pos := PackedVector3Array()
			pos.resize(vs.size())
			var da_cabeca := PackedByteArray()
			da_cabeca.resize(vs.size())
			var matrizes: Dictionary = {}   # índice do vínculo -> [matriz, osso]
			for v in vs.size():
				var q := Vector3.ZERO
				var peso_cabeca := 0.0
				var total := 0.0
				for k in por:
					var w := ws[v * por + k]
					if w <= 0.0:
						continue
					var b := bs[v * por + k]
					if not matrizes.has(b):
						var osso := b
						var vinculo := Transform3D.IDENTITY
						if pele != null:
							osso = pele.get_bind_bone(b)
							if osso < 0:
								osso = esq.find_bone(pele.get_bind_name(b))
							vinculo = pele.get_bind_pose(b)
						else:
							vinculo = esq.get_bone_global_rest(b).affine_inverse()
						matrizes[b] = [esq.get_bone_global_rest(osso) * vinculo if osso >= 0 else Transform3D.IDENTITY, osso]
					q += (matrizes[b][0] as Transform3D) * vs[v] * w
					total += w
					if familia.has(matrizes[b][1]):
						peso_cabeca += w
				pos[v] = q / total if total > 0.0 else vs[v]
				da_cabeca[v] = 1 if peso_cabeca > total * 0.5 else 0
				if da_cabeca[v] == 1:
					soma_lado += pos[v].dot(lado)
					n_lado += 1
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var n_tri := (idx.size() if not idx.is_empty() else vs.size()) / 3
			for t in n_tri:
				var a := idx[t * 3] if not idx.is_empty() else t * 3
				var b2 := idx[t * 3 + 1] if not idx.is_empty() else t * 3 + 1
				var c := idx[t * 3 + 2] if not idx.is_empty() else t * 3 + 2
				if da_cabeca[a] + da_cabeca[b2] + da_cabeca[c] >= 2:
					tris.append(pos[a])
					tris.append(pos[b2])
					tris.append(pos[c])
	# ponto do eixo da cabeça, posto no plano de simetria da malha (os ossos de alguns modelos ficam fora do meio)
	var eixo: Vector3 = rep_h.origin + focinho * float(cfg[1])
	if n_lado > 0:
		eixo += lado * (soma_lado / n_lado - eixo.dot(lado))
	var el := deg_to_rad(float(cfg[2]))
	var fr := deg_to_rad(float(cfg[3]))
	var para_osso := rep_h.affine_inverse()
	var olhos: Array = []
	for s in [-1.0, 1.0]:
		var fora: Vector3 = (lado * s * cos(el) * cos(fr) + frente * cos(el) * sin(fr) + cima * sin(el)).normalized()
		var origem: Vector3 = eixo + fora * comp * 4.0
		var melhor := 1e9
		var toque: Vector3 = eixo + fora * comp * 0.3   # reserva, se o raio não achar a pele
		for t in tris.size() / 3:
			var h: Variant = Geometry3D.ray_intersects_triangle(origem, -fora, tris[t * 3], tris[t * 3 + 1], tris[t * 3 + 2])
			if h != null and origem.distance_to(h) < melhor:
				melhor = origem.distance_to(h)
				toque = h
		var centro: Vector3 = toque - fora * raio * 0.45   # meio afundado na pele
		olhos.append([para_osso * centro, (para_osso.basis * (fora + frente * 2.2 + cima * 0.2)).normalized(), (para_osso.basis * cima).normalized()])
	return [olhos, raio]


## Disco: uma bola achatada na direção `para` (espessura = fração do raio), para pupila e brilho ficarem rentes ao olho.
static func _disco(pai: Node3D, pos: Vector3, para: Vector3, cima: Vector3, raio: float, espessura: float, cor: Color, aspereza: float) -> void:
	var z := para.normalized()
	var x := cima.cross(z)
	x = x.normalized() if x.length() > 0.01 else z.cross(Vector3.RIGHT).normalized()
	var y := z.cross(x)
	_bola(pai, pos, raio, cor, aspereza)
	var mi := pai.get_child(pai.get_child_count() - 1) as MeshInstance3D
	mi.transform = Transform3D(Basis(x, y, z) * Basis.from_scale(Vector3(1.0, 1.0, espessura)), pos)


static func _bola(pai: Node3D, pos: Vector3, raio: float, cor: Color, aspereza: float) -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = raio
	s.height = raio * 2.0
	s.radial_segments = 12
	s.rings = 6
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = aspereza
	m.metallic_specular = 0.8
	s.material = m
	mi.mesh = s
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(mi)
