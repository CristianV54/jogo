class_name CasarioDoReino
extends Node3D
## O CASARIO DE VALDORIA: a cidade apertada dentro da muralha, casa colada em casa, em fileiras que dão a volta no rochedo
## do Castelo (referência do Cristian: cidade medieval murada, com o castelo branco no alto, no centro).
## As casas ficam em fileiras duplas, fundo com fundo, com uma viela entre um par e o seguinte. Não há casa em cima de rua,
## travessa, praça (mercado, quartel, estábulos), encosta do rochedo ou muralha.
## Cada casa é um sobrado de 2 ou 3 andares: corpo com a fachada pintada (enxaimel ou pedra, com janelas e porta) e telhado
## de duas águas (telha ou ardósia). São milhares, então são desenhadas em MultiMesh por setor da cidade (poucas chamadas
## de desenho, e o motor esconde os setores fora da tela). A colisão é uma caixa por casa. Não se entra nelas: as casas
## em que se entra são as das praças (ver Povoado).

const FILEIRAS := [221.0, 231.0, 247.0, 277.0, 287.0, 304.0, 314.0, 331.0, 341.0, 358.0, 368.0, 383.5, 414.0, 424.0, 441.0, 451.0]   # raio do meio de cada fileira
const SETORES := 12
const TONS_DE_PAREDE := [Color(1.0, 0.98, 0.92), Color(0.98, 0.9, 0.76), Color(0.9, 0.86, 0.8), Color(1.0, 0.86, 0.7), Color(0.86, 0.9, 0.84), Color(0.94, 0.8, 0.72)]
const TONS_DE_TELHADO := [Color(0.86, 0.36, 0.24), Color(0.74, 0.3, 0.2), Color(0.9, 0.48, 0.28), Color(0.6, 0.26, 0.2), Color(0.42, 0.44, 0.56), Color(0.5, 0.36, 0.3)]

var mundo: Mundo
var lotes: Array = []   # um por casa: {"p": Vector2, "larg": float, "prof": float, "giro": float, "alt": float}


func montar() -> void:
	name = "CasarioDoReino"
	var c: Vector2 = MundoDados.REINO["centro"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 4711
	var corpos := {}     # "setor_estilo" -> [transformações, cores]
	var telhados := {}   # setor -> [transformações, cores]
	var solidos := StaticBody3D.new()
	solidos.name = "Solidos"
	add_child(solidos)
	for i in FILEIRAS.size():
		var raio_base: float = FILEIRAS[i]
		var ang := rng.randf() * 0.05
		while ang < TAU - 0.012:
			var larg := rng.randf_range(6.4, 11.0)
			var meio := ang + larg / raio_base / 2.0
			ang += (larg + rng.randf_range(0.2, 0.9)) / raio_base
			var r := raio_base + _torto(raio_base, meio) + rng.randf_range(-0.7, 0.7)   # a fileira serpenteia e cada casa avança ou recua um pouco
			var p := c + Vector2.from_angle(meio) * r
			var prof := rng.randf_range(7.6, 9.4)
			if not _livre(p, larg):
				continue
			var sorte := rng.randf()
			var andares := 4 if sorte < 0.14 else (3 if sorte < 0.55 else (2 if sorte < 0.92 else 1))
			var alt := andares * 2.75 + rng.randf_range(0.0, 0.9)
			var torre := rng.randf() < 0.035   # de vez em quando uma casa-torre de pedra, bem mais alta que as vizinhas
			if torre:
				alt = rng.randf_range(15.0, 21.0)
				larg = minf(larg, 8.0)
			var giro := -meio + PI / 2.0 + rng.randf_range(-0.1, 0.1)   # eixo X da casa ao longo da fileira; Z na direção do raio
			var y := 1e9   # a casa assenta no ponto mais baixo do lote (a cidade é em ladeira) e desce um pouco abaixo do chão
			for d in [Vector2(0, 0), Vector2(4, 4), Vector2(-4, 4), Vector2(4, -4), Vector2(-4, -4)]:
				y = minf(y, mundo.terreno.altura_em(p.x + d.x, p.y + d.y))
			y -= 0.4
			alt += 1.2   # o que desceu e o desnível do lote
			var base := Basis(Vector3.UP, giro)
			var setor := int(meio / TAU * SETORES) % SETORES
			var estilo := "pedra" if torre or rng.randf() < 0.28 else "enxaimel"
			var chave := "%d_%s" % [setor, estilo]
			if not corpos.has(chave):
				corpos[chave] = [[], []]
			corpos[chave][0].append(Transform3D(base.scaled_local(Vector3(larg, alt, prof)), Vector3(p.x, y + alt / 2.0, p.y)))
			corpos[chave][1].append(TONS_DE_PAREDE[rng.randi() % TONS_DE_PAREDE.size()] if estilo == "enxaimel" else Color(0.92, 0.9, 0.86) * rng.randf_range(0.85, 1.0))
			if not telhados.has(setor):
				telhados[setor] = [[], []]
			var alt_telhado := rng.randf_range(2.8, 5.4)
			# o prisma tem a cumeeira no eixo Z dele: gira 90 graus para a cumeeira correr ao longo da fileira (uma em cada cinco fica de empena para a rua)
			var virar := 0.0 if rng.randf() < 0.2 else PI / 2.0
			var tam_telhado := Vector3(prof + 1.0, alt_telhado, larg + 0.5) if virar > 0.0 else Vector3(larg + 0.5, alt_telhado, prof + 1.0)
			telhados[setor][0].append(Transform3D((base * Basis(Vector3.UP, virar)).scaled_local(tam_telhado), Vector3(p.x, y + alt + alt_telhado / 2.0, p.y)))
			telhados[setor][1].append(TONS_DE_TELHADO[rng.randi() % TONS_DE_TELHADO.size()] * rng.randf_range(0.82, 1.0))
			var cs := CollisionShape3D.new()
			var caixa := BoxShape3D.new()
			caixa.size = Vector3(larg, alt + 3.0, prof)
			cs.shape = caixa
			cs.position = Vector3(p.x, y + (alt + 3.0) / 2.0, p.y)
			cs.rotation.y = giro
			solidos.add_child(cs)
			lotes.append({"p": p, "larg": larg, "prof": prof, "giro": giro, "alt": alt})
	var caixa_m := BoxMesh.new()
	var prisma := PrismMesh.new()
	for chave in corpos:
		_multimesh("Corpos_" + String(chave), caixa_m, Fachadas.material(String(chave).get_slice("_", 1)), corpos[chave][0], corpos[chave][1])
	for setor in telhados:
		_multimesh("Telhados_%d" % setor, prisma, Fachadas.material("telhado"), telhados[setor][0], telhados[setor][1])
	print("CasarioDoReino: ", lotes.size(), " casas em ", FILEIRAS.size(), " fileiras")


## O lote está livre? Fora de rua e travessa, de praça, da encosta do rochedo e da faixa da muralha.
func _livre(p: Vector2, larg: float) -> bool:
	if mundo.terreno.distancia_caminho(p.x, p.y) < larg / 2.0 + 3.6 or mundo._em_alguma_area(p):
		return false
	for pid in mundo.povoados:
		if p.distance_to(mundo.povoados[pid]["centro"]) < float(mundo.povoados[pid]["raio"]) + 5.0:
			return false
	var h0 := mundo.terreno.altura_em(p.x, p.y)
	for d in [Vector2(5, 0), Vector2(-5, 0), Vector2(0, 5), Vector2(0, -5)]:
		if absf(mundo.terreno.altura_em(p.x + d.x, p.y + d.y) - h0) > 0.8:   # ladeira da colina passa; paredão do rochedo, não
			return false
	return true


## Quanto a fileira sai do círculo perfeito naquele ângulo: as ruas de cidade antiga são tortas. Some junto das duas ruas
## em anel (que são círculos certos) para nenhuma casa cair em cima delas.
func _torto(raio: float, ang: float) -> float:
	var onda := sin(ang * 5.0 + 1.3) * 0.6 + sin(ang * 11.0 + 0.4) * 0.4
	if raio > 262.0 and raio < 400.0:
		return onda * 6.0 * sin(PI * (raio - 262.0) / 138.0)
	if raio > 400.0:
		return onda * 2.5 * sin(PI * (raio - 400.0) / 70.0)
	return 0.0


func _multimesh(nome: String, malha: Mesh, mat: Material, transformacoes: Array, cores: Array) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = malha
	mm.instance_count = transformacoes.size()
	for i in transformacoes.size():
		mm.set_instance_transform(i, transformacoes[i])
		mm.set_instance_color(i, cores[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = nome
	inst.multimesh = mm
	inst.material_override = mat
	add_child(inst)
