class_name Terreno
extends Node3D
## Terreno procedural pintado por vértice (grama, mata, terra, pedra).
## Plano e limpo numa clareira central (0, 0), com colinas fora dela e caminhos de terra.

@export var tamanho := 320.0
@export var passo := 2.0
@export var semente := 7
@export var amplitude := 16.0
@export var frequencia := 0.011
@export var clareira_raio := 45.0
## Áreas aplanadas: cada Vector3 é (x, z, raio). O terreno vira plano na altura do centro, com 10 m de transição.
@export var planos: Array[Vector3] = []
@export var inclinacao := Vector2.ZERO   # sobe/desce suave em x e z (a encosta do Pomar Alto)
@export var cor_grama := Color(0.34, 0.5, 0.21)
@export var cor_mata := Color(0.2, 0.34, 0.16)
@export var cor_terra := Color(0.47, 0.36, 0.23)
@export var cor_pedra := Color(0.5, 0.48, 0.45)

## Rios e vales escavados no terreno. Cada rio é um Dictionary:
##   "pontos": PackedVector2Array (x, z) do eixo (use Terreno.curva para suavizar)
##   "largura": largura do leito, "margem": largura da barranca que sobe de volta ao chão, "fundo": profundidade do leito
##   "agua": se tem água viva (false = só um vale), "vaus": lista de Vector2 onde o leito é raso (dá para atravessar)
## O leito acompanha a altura do chão em volta (a água fica 0,55 m abaixo do chão no eixo), então o rio segue as colinas.
@export var rios: Array = []

## Mundo contínuo: nas bordas do terreno a altura e a cor se misturam com as do chão do mundo, para não haver emenda.
## `origem` é a posição desta área no mundo; `externa(x, z)` e `cor_externa(x, z)` recebem coordenadas do MUNDO.
@export var borda := 40.0
var externa: Callable
var cor_externa: Callable
var origem := Vector2.ZERO

## Cada caminho é um PackedVector2Array de pontos (x, z).
var caminhos: Array = []
var _rio_caixa: Array[Rect2] = []
var corpo: StaticBody3D
var _ruido := FastNoiseLite.new()
var _ruido_fino := FastNoiseLite.new()


func gerar() -> void:
	_preparar_rios()
	_ruido.seed = semente
	_ruido.frequency = frequencia
	_ruido.fractal_octaves = 4
	_ruido_fino.seed = semente + 1
	_ruido_fino.frequency = frequencia * 7.0

	var malha := _malha()
	var mi := MeshInstance3D.new()
	mi.name = "Superficie"
	mi.mesh = malha
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mi.material_override = mat
	add_child(mi)

	corpo = StaticBody3D.new()
	corpo.name = "Colisao"
	var cs := CollisionShape3D.new()
	cs.shape = malha.create_trimesh_shape()
	corpo.add_child(cs)
	add_child(corpo)
	for r in rios:
		if r.get("agua", true):
			add_child(_agua(r))


func altura_em(x: float, z: float) -> float:
	var h := _altura_base(x, z)
	for i in rios.size():
		if _rio_caixa[i].has_point(Vector2(x, z)):
			h = _aplicar_rio(rios[i], Vector2(x, z), h)
	return h


## Altura sem os rios (colinas, clareira e áreas aplanadas).
func _altura_base(x: float, z: float) -> float:
	var h := _altura_crua(x, z)
	for p in planos:
		var dx := x - p.x
		var dz := z - p.y
		var lim := p.z + 10.0
		if dx * dx + dz * dz < lim * lim:
			h = lerpf(h, _altura_crua(p.x, p.y), 1.0 - smoothstep(p.z, lim, sqrt(dx * dx + dz * dz)))
	if externa.is_valid():
		var w := _peso_da_borda(x, z)
		if w > 0.0:
			h = lerpf(h, externa.call(origem.x + x, origem.y + z), w)
	return h


## 1 na beirada do terreno, 0 a `borda` metros para dentro.
func _peso_da_borda(x: float, z: float) -> float:
	var d := minf(tamanho / 2.0 - absf(x), tamanho / 2.0 - absf(z))
	return 1.0 - smoothstep(0.0, borda, d)


func _preparar_rios() -> void:
	_rio_caixa.clear()
	for r in rios:
		var pts: PackedVector2Array = r["pontos"]
		var ext := float(r["largura"]) / 2.0 + float(r["margem"]) + 1.5
		var menor := pts[0]
		var maior := pts[0]
		for p in pts:
			menor = menor.min(p)
			maior = maior.max(p)
		_rio_caixa.append(Rect2(menor - Vector2(ext, ext), maior - menor + Vector2(ext, ext) * 2.0))


## Ponto do eixo mais perto de `p`: devolve [distância, ponto].
func _eixo_mais_perto(p: Vector2, pts: PackedVector2Array) -> Array:
	var melhor := 1e9
	var q := pts[0]
	for i in range(pts.size() - 1):
		var a := pts[i]
		var ab := pts[i + 1] - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var c := a + ab * t
		var d := p.distance_to(c)
		if d < melhor:
			melhor = d
			q = c
	return [melhor, q]


func _aplicar_rio(r: Dictionary, p: Vector2, h: float) -> float:
	var meia := float(r["largura"]) / 2.0
	var margem := float(r["margem"])
	var par := _eixo_mais_perto(p, r["pontos"])
	var d: float = par[0]
	if d > meia + 3.5 + margem:
		return h
	var q: Vector2 = par[1]
	var nivel := _altura_base(q.x, q.y) - 0.55
	var fundo := float(r["fundo"])
	for v in r.get("vaus", []):
		fundo *= 1.0 - 0.85 * (1.0 - smoothstep(0.0, 7.0, q.distance_to(v)))   # o vau é raso
	var leito := meia + 3.5   # o leito é mais largo que a água: com o chão em grade de 8 m um leito estreito sumia entre os vértices
	if d <= leito:
		return nivel - fundo * (1.0 - smoothstep(0.0, 1.0, d / leito)) - 0.15
	return lerpf(nivel - 0.15, h, smoothstep(0.0, 1.0, (d - leito) / margem))


## Distância ao eixo do rio com água mais perto (para pintar a lama da margem e não plantar árvore na água).
func distancia_rio(x: float, z: float) -> float:
	var melhor := 1e9
	for i in rios.size():
		if rios[i].get("agua", true) and _rio_caixa[i].has_point(Vector2(x, z)):
			var par := _eixo_mais_perto(Vector2(x, z), rios[i]["pontos"])
			melhor = minf(melhor, float(par[0]) - float(rios[i]["largura"]) / 2.0)
	return melhor


## Está na água ou a menos de `folga` metros dela?
func na_agua(x: float, z: float, folga := 2.0) -> bool:
	return distancia_rio(x, z) < folga


## Suaviza pontos de controle (Catmull-Rom) em pontos a cada ~`passo` metros. O resultado passa pelos pontos de controle.
static func curva(ctrl: Array, passo := 3.0) -> PackedVector2Array:
	var saida := PackedVector2Array()
	for i in range(ctrl.size() - 1):
		var p0: Vector2 = ctrl[maxi(i - 1, 0)]
		var p1: Vector2 = ctrl[i]
		var p2: Vector2 = ctrl[i + 1]
		var p3: Vector2 = ctrl[mini(i + 2, ctrl.size() - 1)]
		var n := maxi(1, int(p1.distance_to(p2) / passo))
		for k in n:
			var t := float(k) / n
			saida.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t))
	saida.append(ctrl[ctrl.size() - 1])
	return saida


## Fita de água ao longo do eixo, 0,55 m abaixo do chão do eixo, com shader de correnteza e espuma na margem.
func _agua(r: Dictionary) -> MeshInstance3D:
	var pts: PackedVector2Array = r["pontos"]
	var meia := float(r["largura"]) / 2.0 + 5.0   # larga de propósito: o chão esconde o excesso e a margem da água fica onde o chão cruza
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var acumulado := 0.0
	var anteriores: Array = []
	for i in pts.size():
		var dir := (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var lado := Vector2(-dir.y, dir.x) * meia
		var y := _altura_base(pts[i].x, pts[i].y) - 0.55
		if i > 0:
			acumulado += pts[i].distance_to(pts[i - 1])
		var a := Vector3(pts[i].x + lado.x, y, pts[i].y + lado.y)
		var b := Vector3(pts[i].x - lado.x, y, pts[i].y - lado.y)
		anteriores.append([a, b, acumulado])
	for i in range(anteriores.size() - 1):
		var a0: Vector3 = anteriores[i][0]
		var b0: Vector3 = anteriores[i][1]
		var a1: Vector3 = anteriores[i + 1][0]
		var b1: Vector3 = anteriores[i + 1][1]
		var u0: float = anteriores[i][2]
		var u1: float = anteriores[i + 1][2]
		for tri in [[[a0, 0.0, u0], [b0, 1.0, u0], [a1, 0.0, u1]], [[b0, 1.0, u0], [b1, 1.0, u1], [a1, 0.0, u1]]]:
			for v in tri:
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(v[1], v[2]))
				st.add_vertex(v[0])
	var mat := material_agua()
	var mi := MeshInstance3D.new()
	mi.name = "AguaDoRio"
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pedras_da_margem(mi, r)
	return mi


## Material da água (rios e mar): cor por profundidade lida do buffer de profundidade, espuma onde o chão encosta.
static func material_agua() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_schlick_ggx;
uniform sampler2D prof : hint_depth_texture, repeat_disable, filter_nearest;
void fragment() {
	float d = textureLod(prof, SCREEN_UV, 0.0).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, d);
	vec4 v = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	v.xyz /= v.w;
	float fundo = clamp(-v.z + VERTEX.z, 0.0, 6.0);          // quanto de água há por baixo deste ponto
	float fluxo = sin(UV.y * 0.7 - TIME * 1.5 + sin(UV.x * 7.0 + TIME * 0.6) * 1.2);
	float faixa = smoothstep(0.6, 0.98, fluxo);
	vec3 raso = vec3(0.2, 0.6, 0.64);
	vec3 fundo_c = vec3(0.04, 0.28, 0.42);
	vec3 c = mix(raso, fundo_c, smoothstep(0.1, 1.3, fundo));
	c += faixa * 0.07 * (1.0 - smoothstep(0.0, 1.2, fundo));
	float espuma = 1.0 - smoothstep(0.0, 0.16, fundo);         // espuma onde o chão encosta na água
	ALBEDO = mix(c, vec3(0.9, 0.96, 0.97), espuma * 0.7);
	ALPHA = clamp(0.35 + fundo * 0.9 + espuma * 0.4, 0.0, 0.92);
	ROUGHNESS = 0.1;
	SPECULAR = 0.7;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	return mat


## Pedras e seixos nas duas margens, como num rio de verdade (só visual, sem colisão; o vau fica limpo).
func _pedras_da_margem(pai: MeshInstance3D, r: Dictionary) -> void:
	var pts: PackedVector2Array = r["pontos"]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pts[0].x * 7.0 + pts[0].y * 13.0)
	var lista: Array[Transform3D] = []
	for i in range(pts.size() - 1):
		var a := pts[i]
		var b := pts[i + 1]
		var comp := a.distance_to(b)
		if comp < 0.01:
			continue
		var dir := (b - a) / comp
		var lado := Vector2(-dir.y, dir.x)
		var t := 0.0
		while t < comp:
			var c0 := a + dir * t
			var no_vau := false
			for v in r.get("vaus", []):
				if c0.distance_to(v) < 9.0:
					no_vau = true
			if not no_vau:
				for sg in [-1.0, 1.0]:
					if rng.randf() < 0.7:
						var c: Vector2 = c0 + lado * sg * (float(r["largura"]) / 2.0 + rng.randf_range(-0.2, 1.6))
						var e := rng.randf_range(0.3, 1.0)
						var base := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(e * 1.2, e * rng.randf_range(0.5, 0.9), e))
						lista.append(Transform3D(base, Vector3(c.x, altura_em(c.x, c.y) - 0.1, c.y)))
			t += rng.randf_range(1.5, 3.0)
	if lista.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = FabricaNatureza.pedra(11.0)
	mm.instance_count = lista.size()
	for i in lista.size():
		mm.set_instance_transform(i, lista[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = "PedrasDaMargem"
	inst.multimesh = mm
	inst.material_override = FabricaNatureza.material()
	inst.visibility_range_end = 220.0
	pai.add_child(inst)


func _altura_crua(x: float, z: float) -> float:
	var d := Vector2(x, z).length()
	var m := smoothstep(clareira_raio, clareira_raio * 1.9, d)
	var n := _ruido.get_noise_2d(x, z) * 0.5 + 0.5
	return (n * amplitude + _ruido_fino.get_noise_2d(x, z) * 1.3) * m + x * inclinacao.x + z * inclinacao.y


func normal_em(x: float, z: float) -> Vector3:
	var e := passo
	var dx := altura_em(x + e, z) - altura_em(x - e, z)
	var dz := altura_em(x, z + e) - altura_em(x, z - e)
	return Vector3(-dx, 2.0 * e, -dz).normalized()


func distancia_caminho(x: float, z: float) -> float:
	var melhor := 1e9
	var p := Vector2(x, z)
	for c in caminhos:
		for i in range(c.size() - 1):
			var a: Vector2 = c[i]
			var b: Vector2 = c[i + 1]
			var ab := b - a
			var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			melhor = minf(melhor, p.distance_to(a + ab * t))
	return melhor


func cor_em(x: float, z: float) -> Color:
	return _cor_vertice(x, z, normal_em(x, z))


## Cor do chão num ponto, dado o vetor normal já calculado (grama, mata, pedra nas encostas, terra no caminho, lama no rio).
func _cor_vertice(x: float, z: float, n: Vector3) -> Color:
	var d := Vector2(x, z).length()
	var c := cor_grama.lerp(cor_mata, smoothstep(clareira_raio * 1.05, clareira_raio * 2.2, d))
	c = c * (0.92 + 0.16 * (_ruido_fino.get_noise_2d(x * 3.1, z * 3.1) * 0.5 + 0.5))
	var inclinacao := 1.0 - n.y
	c = c.lerp(cor_pedra, smoothstep(0.22, 0.45, inclinacao))
	c = c.lerp(cor_terra, 1.0 - smoothstep(1.4, 3.2, distancia_caminho(x, z)))
	c = c.lerp(cor_terra, 0.55 * (1.0 - smoothstep(5.0, 15.0, d)))   # chão pisado em volta da fogueira
	var dr := distancia_rio(x, z)
	if dr < 3.5:   # lama e areia na margem do rio
		c = c.lerp(Color(0.34, 0.29, 0.2), 1.0 - smoothstep(0.0, 3.5, dr))
	if cor_externa.is_valid():
		var w := _peso_da_borda(x, z)
		if w > 0.0:
			c = c.lerp(cor_externa.call(origem.x + x, origem.y + z), w)
	return c


## Malha em grade com vértices compartilhados: a altura de cada vértice é calculada uma vez só e a normal sai dos vizinhos.
func _malha() -> ArrayMesh:
	var n := int(tamanho / passo)
	var meia := tamanho / 2.0
	var lado := n + 1
	var alturas := PackedFloat32Array()
	alturas.resize(lado * lado)
	for i in lado:
		for j in lado:
			alturas[i * lado + j] = altura_em(-meia + i * passo, -meia + j * passo)
	var vertices := PackedVector3Array()
	var normais := PackedVector3Array()
	var cores := PackedColorArray()
	vertices.resize(lado * lado)
	normais.resize(lado * lado)
	cores.resize(lado * lado)
	for i in lado:
		for j in lado:
			var x := -meia + i * passo
			var z := -meia + j * passo
			var h := alturas[i * lado + j]
			var hx0 := alturas[maxi(i - 1, 0) * lado + j]
			var hx1 := alturas[mini(i + 1, n) * lado + j]
			var hz0 := alturas[i * lado + maxi(j - 1, 0)]
			var hz1 := alturas[i * lado + mini(j + 1, n)]
			var dx := (hx1 - hx0) / ((mini(i + 1, n) - maxi(i - 1, 0)) * passo)
			var dz := (hz1 - hz0) / ((mini(j + 1, n) - maxi(j - 1, 0)) * passo)
			var normal := Vector3(-dx, 1.0, -dz).normalized()
			var k := i * lado + j
			vertices[k] = Vector3(x, h, z)
			normais[k] = normal
			cores[k] = _cor_vertice(x, z, normal).srgb_to_linear()   # cor de vértice é linear no Godot
	var indices := PackedInt32Array()
	indices.resize(n * n * 6)
	var q := 0
	for i in n:
		for j in n:
			var p00 := i * lado + j
			var p10 := (i + 1) * lado + j
			var p01 := i * lado + j + 1
			var p11 := (i + 1) * lado + j + 1
			for v in [p00, p10, p01, p10, p11, p01]:   # sentido horário visto de cima (a face que o Godot desenha)
				indices[q] = v
				q += 1
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normais
	arrays[Mesh.ARRAY_COLOR] = cores
	arrays[Mesh.ARRAY_INDEX] = indices
	var malha := ArrayMesh.new()
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return malha
