class_name MuralhaDoReino
extends Node3D
## A muralha de Valdoria: segue o contorno irregular de MundoDados.ponto_da_muralha e é montada com o kit PecasDaMuralha
## (lanços com soco, cornija e ameias; torres de vigia; escadas para o caminho de ronda; portão com arco). Abre-se um
## PORTÃO em todo ponto onde uma estrada cruza o contorno. O kit foi aprovado antes em tools/bancada_construcao.gd.

const PASSOS := 360
const TORRES := 32

var mundo: Mundo
var portoes: Array[Vector2] = []   # onde ficou cada portão (para o mapa e para os testes)
var torres := 0
var escadas := 0


func montar() -> void:
	name = "MuralhaDoReino"
	for id in mundo.estradas:   # portões: onde cada estrada cruza a muralha
		var pts: PackedVector2Array = mundo.estradas[id]
		for i in pts.size() - 1:
			if MundoDados.ate_a_muralha(pts[i].x, pts[i].y) * MundoDados.ate_a_muralha(pts[i + 1].x, pts[i + 1].y) <= 0.0:
				var g := pts[i].lerp(pts[i + 1], 0.5)
				var novo := true
				for outro in portoes:
					if outro.distance_to(g) < 40.0:
						novo = false
				if novo:
					portoes.append(g)
	var kit := PecasDaMuralha.new()
	kit.name = "Pecas"
	add_child(kit)
	var meia_casa := PecasDaMuralha.MEIA_CASA_DO_PORTAO + PecasDaMuralha.RAIO_TORRE_DO_PORTAO - 1.5   # até dentro da torre do portão
	for k in PASSOS:
		var p0 := MundoDados.ponto_da_muralha(TAU * k / PASSOS)
		var p1 := MundoDados.ponto_da_muralha(TAU * (k + 1) / PASSOS)
		if _perto_de_portao((p0 + p1) / 2.0, meia_casa):
			continue
		kit.lanco(_no_chao(p0), _no_chao(p1), _fora(p0, p1))
	for k in TORRES:   # torres de vigia; a cada quatro, uma escada para o caminho de ronda
		var a := TAU * (k + 0.5) / TORRES
		var p := MundoDados.ponto_da_muralha(a)
		if _perto_de_portao(p, 34.0):
			continue
		var q := MundoDados.ponto_da_muralha(a + 0.01)
		var tang := (q - p).normalized()
		var fora := _fora(p, q)
		kit.torre(_no_chao(p), tang)
		torres += 1
		if k % 4 == 1:
			var pe := p + tang * (PecasDaMuralha.RAIO_TORRE + 2.5) - fora * (PecasDaMuralha.ESPESSURA / 2.0)
			kit.escada(_no_chao(pe), tang, fora)
			escadas += 1
	for g in portoes:   # o portão fica alinhado com a muralha naquele ponto
		var a := atan2(g.y / MundoDados.MURALHA_EIXOS.y, g.x / MundoDados.MURALHA_EIXOS.x)
		var fora := _fora(MundoDados.ponto_da_muralha(a - 0.01), MundoDados.ponto_da_muralha(a + 0.01))
		kit.portao(_no_chao(g), fora)
	kit.fechar()
	print("MuralhaDoReino: ", torres, " torres de vigia, ", escadas, " escadas, ", portoes.size(), " portões")


func _no_chao(p: Vector2) -> Vector3:
	return Vector3(p.x, mundo.terreno.altura_em(p.x, p.y), p.y)


## Direção para fora da cidade, perpendicular ao trecho p0 -> p1.
func _fora(p0: Vector2, p1: Vector2) -> Vector2:
	var t := (p1 - p0).normalized()
	var n := Vector2(t.y, -t.x)
	return n if n.dot((p0 + p1) / 2.0) > 0.0 else -n


func _perto_de_portao(p: Vector2, raio: float) -> bool:
	for g in portoes:
		if p.distance_to(g) < raio:
			return true
	return false
