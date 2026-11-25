class_name CalcamentoDoReino
extends MeshInstance3D
## O CHÃO DA CIDADE: dentro da muralha do reino o chão não é terra nem pasto, é CALÇADO DE PEDRA. Esta é uma camada fina
## (6 cm acima do terreno, nos mesmos pontos da grade dele, para não brigar com ele) que cobre a cidade inteira, com o
## desenho de pedras de calçamento. Nas ruas e travessas a pedra é mais clara e lisa; nas vielas, mais escura e miúda.
## Não tem colisão: quem segura o Torin é o terreno, logo abaixo.

var mundo: Mundo


func montar() -> void:
	name = "CalcamentoDoReino"
	var c: Vector2 = MundoDados.REINO["centro"]
	var passo := 4.0
	var n := int(ceil(float(MundoDados.REINO["raio"]) / passo)) + 2
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cantos := [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]   # a mesma diagonal do terreno
	for i in range(-n, n):
		for j in range(-n, n):
			var meio := c + Vector2((i + 0.5) * passo, (j + 0.5) * passo)
			var pen := MundoDados.penhasco(meio.x, meio.y)
			var no_alto := float(pen[2]) <= 0.99 or bool(pen[1])   # o pátio da cidadela e o piso da rampa também são calçados
			if MundoDados.ate_a_muralha(meio.x, meio.y) > -1.5 or (float(pen[0]) > 0.3 and not no_alto):
				continue   # só dentro da muralha, e não em cima da rocha nua do penhasco
			for k in cantos:
				var q: Vector2 = c + Vector2((i + k.x) * passo, (j + k.y) * passo)
				var rua := 1.0 - smoothstep(4.0, 7.5, mundo.terreno.distancia_caminho(q.x, q.y))
				st.set_color(Color(0.46, 0.45, 0.42) if no_alto else Color(0.26, 0.25, 0.24).lerp(Color(0.37, 0.36, 0.33), rua))   # no alto a pedra é clara, como a cidadela   # pedra cinzenta (clara demais estourava de branco ao sol)
				st.set_normal(Vector3.UP)
				st.add_vertex(Vector3(q.x, mundo.terreno.altura_em(q.x, q.y) + 0.06, q.y))
	st.generate_normals()
	mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_texture = Pedra.calcamento()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.95
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.3, 0.3, 0.3)   # a imagem (umas 9 pedras de lado) cobre 3,3 m: pedra de calçamento de ~35 cm
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
